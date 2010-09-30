require 'test_helper'

class FuelOilParser
  def initialize(options = {})
    # nothing
  end
  def add_hints!(bus)
    bus[:sheet] = 'Data 1'
    bus[:skip] = 2
    bus[:select] = lambda { |row| row['year'] > 1989 }
  end
  def apply(row)
    virtual_rows = []
    row.keys.grep(/(.+) Residual Fuel Oil/) do |location_column_name|
      first_part = $1
      next if (cost = row[location_column_name]).blank? or (date = row['Date']).blank?
      if first_part.start_with?('U.S.')
        locatable = "united_states (Country)"
      elsif first_part.include?('PADD')
        /\(PADD (.*)\)/.match(first_part)
        padd_part = $1
        next if padd_part == '1' # skip PADD 1 because we always prefer subdistricts
        locatable = "#{padd_part} (PetroleumAdministrationForDefenseDistrict)"
      else
        locatable = "#{first_part} (State)"
      end
      date = Time.parse(date)
      virtual_rows << {
        'locatable' => locatable,
        'cost' => cost,
        'year' => date.year,
        'month' => date.month
      }
    end
    virtual_rows
  end
end

class AircraftGuru
  def is_a_dc_plane?(row)
    row['Designator'] =~ /^DC\d/i
  end
  
  # def is_a_crj_900?(row)
  #   row['Designator'].downcase == 'crj9'
  # end
  
  def is_a_g159?(row)
    row['Designator'] =~ /^G159$/
  end

  def is_a_galx?(row)
    row['Designator'] =~ /^GALX$/
  end
  
  def method_missing(method_id, *args, &block)
    if method_id.to_s =~ /\Ais_n?o?t?_?attributed_to_([^\?]+)/
      manufacturer_name = $1
      manufacturer_regexp = Regexp.new(manufacturer_name.gsub('_', ' ?'), Regexp::IGNORECASE)
      matches = manufacturer_regexp.match(args.first['Manufacturer']) # row['Manufacturer'] =~ /mcdonnell douglas/i
      method_id.to_s.include?('not_attributed') ? matches.nil? : !matches.nil?
    else
      super
    end
  end
end

class RemoteTableTest < Test::Unit::TestCase
  def setup
    @test2_rows_with_blanks = [
      { 'header4' => '', 'header5' => '', 'header6' => '' },
      { 'header4' => '1 at 4', 'header5' => '1 at 5', 'header6' => '1 at 6' },
      { 'header4' => '', 'header5' => '', 'header6' => '' },
      { 'header4' => '2 at 4', 'header5' => '2 at 5', 'header6' => '2 at 6' },
    ]
    @test2_rows = [
      { 'header4' => '1 at 4', 'header5' => '1 at 5', 'header6' => '1 at 6' },
      { 'header4' => '2 at 4', 'header5' => '2 at 5', 'header6' => '2 at 6' },
    ]
  end
  
  if ENV['ALL'] == 'true' or ENV['SLOW'] == 'true'
    should "open an XLS inside a zip file" do
      t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/02data.zip', :filename => 'guide_jan28.xls')
      assert_equal 'ACURA',      t.rows.first['Manufacturer']
      assert_equal 'NSX',        t.rows.first['carline name']
      assert_equal 'VOLVO',      t.rows.last['Manufacturer']
      assert_equal 'V70 XC AWD', t.rows.last['carline name']
    end
  
    should "not have indifferent string/symbol hash access" do
      t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/02data.zip', :filename => 'guide_jan28.xls')
      assert_equal 'ACURA',      t.rows.first['Manufacturer']
      assert_equal nil,          t.rows.first[:Manufacturer]
    end
  
    should "open a CSV inside a zip file" do
      t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/98guide6.zip', :filename => '98guide6.csv')
      assert_equal 'ACURA',             t.rows.first['Manufacturer']
      assert_equal 'NSX',               t.rows.first['carline name']
      assert_equal 'TOYOTA',            t.rows.last['Manufacturer']
      assert_equal 'RAV4 SOFT TOP 4WD', t.rows.last['carline name']
    end

    should "open a fixed-width file with an inline schema inside a zip file" do
      t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/00data.zip',
                          :filename => 'Gd6-dsc.txt',
                          :format => :fixed_width,
                          :crop => 21..26, # inclusive
                          :cut => '2-',
                          :select => lambda { |row| /\A[A-Z]/.match row['code'] },
                          :schema => [[ 'code',   2, { :type => :string }  ],
                                      [ 'spacer', 2 ],
                                      [ 'name',   52, { :type => :string } ]])
      assert_equal 'regular grade gasoline (octane number of 87)', t.rows.first['name']
      assert_equal 'R',                                            t.rows.first['code']
      assert_equal 'electricity',                                  t.rows.last['name']
      assert_equal 'El',                                           t.rows.last['code']
    end
    
    should "send form data, follow redirects and use a filename glob" do
      url = 'http://www.transtats.bts.gov/DownLoad_Table.asp?Table_ID=293&Has_Group=3&Is_Zipped=0'
      form_data = 'UserTableName=T_100_Segment__All_Carriers&DBShortName=Air_Carriers&RawDataTable=T_T100_SEGMENT_ALL_CARRIER&sqlstr=+SELECT+DEPARTURES_SCHEDULED%2CDEPARTURES_PERFORMED%2CPAYLOAD%2CSEATS%2CPASSENGERS%2CFREIGHT%2CMAIL%2CDISTANCE%2CRAMP_TO_RAMP%2CAIR_TIME%2CUNIQUE_CARRIER%2CAIRLINE_ID%2CUNIQUE_CARRIER_NAME%2CUNIQUE_CARRIER_ENTITY%2CREGION%2CCARRIER%2CCARRIER_NAME%2CCARRIER_GROUP%2CCARRIER_GROUP_NEW%2CORIGIN%2CORIGIN_CITY_NAME%2CORIGIN_CITY_NUM%2CORIGIN_STATE_ABR%2CORIGIN_STATE_FIPS%2CORIGIN_STATE_NM%2CORIGIN_COUNTRY%2CORIGIN_COUNTRY_NAME%2CORIGIN_WAC%2CDEST%2CDEST_CITY_NAME%2CDEST_CITY_NUM%2CDEST_STATE_ABR%2CDEST_STATE_FIPS%2CDEST_STATE_NM%2CDEST_COUNTRY%2CDEST_COUNTRY_NAME%2CDEST_WAC%2CAIRCRAFT_GROUP%2CAIRCRAFT_TYPE%2CAIRCRAFT_CONFIG%2CYEAR%2CQUARTER%2CMONTH%2CDISTANCE_GROUP%2CCLASS%2CDATA_SOURCE+FROM++T_T100_SEGMENT_ALL_CARRIER+WHERE+Month+%3D1+AND+YEAR%3D2008&varlist=DEPARTURES_SCHEDULED%2CDEPARTURES_PERFORMED%2CPAYLOAD%2CSEATS%2CPASSENGERS%2CFREIGHT%2CMAIL%2CDISTANCE%2CRAMP_TO_RAMP%2CAIR_TIME%2CUNIQUE_CARRIER%2CAIRLINE_ID%2CUNIQUE_CARRIER_NAME%2CUNIQUE_CARRIER_ENTITY%2CREGION%2CCARRIER%2CCARRIER_NAME%2CCARRIER_GROUP%2CCARRIER_GROUP_NEW%2CORIGIN%2CORIGIN_CITY_NAME%2CORIGIN_CITY_NUM%2CORIGIN_STATE_ABR%2CORIGIN_STATE_FIPS%2CORIGIN_STATE_NM%2CORIGIN_COUNTRY%2CORIGIN_COUNTRY_NAME%2CORIGIN_WAC%2CDEST%2CDEST_CITY_NAME%2CDEST_CITY_NUM%2CDEST_STATE_ABR%2CDEST_STATE_FIPS%2CDEST_STATE_NM%2CDEST_COUNTRY%2CDEST_COUNTRY_NAME%2CDEST_WAC%2CAIRCRAFT_GROUP%2CAIRCRAFT_TYPE%2CAIRCRAFT_CONFIG%2CYEAR%2CQUARTER%2CMONTH%2CDISTANCE_GROUP%2CCLASS%2CDATA_SOURCE&grouplist=&suml=&sumRegion=&filter1=title%3D&filter2=title%3D&geo=All%A0&time=January&timename=Month&GEOGRAPHY=All&XYEAR=2008&FREQUENCY=1&AllVars=All&VarName=DEPARTURES_SCHEDULED&VarDesc=DepScheduled&VarType=Num&VarName=DEPARTURES_PERFORMED&VarDesc=DepPerformed&VarType=Num&VarName=PAYLOAD&VarDesc=Payload&VarType=Num&VarName=SEATS&VarDesc=Seats&VarType=Num&VarName=PASSENGERS&VarDesc=Passengers&VarType=Num&VarName=FREIGHT&VarDesc=Freight&VarType=Num&VarName=MAIL&VarDesc=Mail&VarType=Num&VarName=DISTANCE&VarDesc=Distance&VarType=Num&VarName=RAMP_TO_RAMP&VarDesc=RampToRamp&VarType=Num&VarName=AIR_TIME&VarDesc=AirTime&VarType=Num&VarName=UNIQUE_CARRIER&VarDesc=UniqueCarrier&VarType=Char&VarName=AIRLINE_ID&VarDesc=AirlineID&VarType=Num&VarName=UNIQUE_CARRIER_NAME&VarDesc=UniqueCarrierName&VarType=Char&VarName=UNIQUE_CARRIER_ENTITY&VarDesc=UniqCarrierEntity&VarType=Char&VarName=REGION&VarDesc=CarrierRegion&VarType=Char&VarName=CARRIER&VarDesc=Carrier&VarType=Char&VarName=CARRIER_NAME&VarDesc=CarrierName&VarType=Char&VarName=CARRIER_GROUP&VarDesc=CarrierGroup&VarType=Num&VarName=CARRIER_GROUP_NEW&VarDesc=CarrierGroupNew&VarType=Num&VarName=ORIGIN&VarDesc=Origin&VarType=Char&VarName=ORIGIN_CITY_NAME&VarDesc=OriginCityName&VarType=Char&VarName=ORIGIN_CITY_NUM&VarDesc=OriginCityNum&VarType=Num&VarName=ORIGIN_STATE_ABR&VarDesc=OriginState&VarType=Char&VarName=ORIGIN_STATE_FIPS&VarDesc=OriginStateFips&VarType=Char&VarName=ORIGIN_STATE_NM&VarDesc=OriginStateName&VarType=Char&VarName=ORIGIN_COUNTRY&VarDesc=OriginCountry&VarType=Char&VarName=ORIGIN_COUNTRY_NAME&VarDesc=OriginCountryName&VarType=Char&VarName=ORIGIN_WAC&VarDesc=OriginWac&VarType=Num&VarName=DEST&VarDesc=Dest&VarType=Char&VarName=DEST_CITY_NAME&VarDesc=DestCityName&VarType=Char&VarName=DEST_CITY_NUM&VarDesc=DestCityNum&VarType=Num&VarName=DEST_STATE_ABR&VarDesc=DestState&VarType=Char&VarName=DEST_STATE_FIPS&VarDesc=DestStateFips&VarType=Char&VarName=DEST_STATE_NM&VarDesc=DestStateName&VarType=Char&VarName=DEST_COUNTRY&VarDesc=DestCountry&VarType=Char&VarName=DEST_COUNTRY_NAME&VarDesc=DestCountryName&VarType=Char&VarName=DEST_WAC&VarDesc=DestWac&VarType=Num&VarName=AIRCRAFT_GROUP&VarDesc=AircraftGroup&VarType=Num&VarName=AIRCRAFT_TYPE&VarDesc=AircraftType&VarType=Char&VarName=AIRCRAFT_CONFIG&VarDesc=AircraftConfig&VarType=Num&VarName=YEAR&VarDesc=Year&VarType=Num&VarName=QUARTER&VarDesc=Quarter&VarType=Num&VarName=MONTH&VarDesc=Month&VarType=Num&VarName=DISTANCE_GROUP&VarDesc=DistanceGroup&VarType=Num&VarName=CLASS&VarDesc=Class&VarType=Char&VarName=DATA_SOURCE&VarDesc=DataSource&VarType=Char'
      t = RemoteTable.new :url => url, :form_data => form_data, :compression => :zip, :glob => '/*.csv'
      assert_equal 'United States of America', t.rows.first['DEST_COUNTRY_NAME']
    end
  end
  
  if ENV['ALL'] == 'true' or ENV['NEW'] == 'true'
  end
  
  if ENV['ALL'] == 'true' or ENV['FAST'] == 'true'
    should "open an XLSX like an array (numbered columns)" do
      t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :headers => false)
      assert_equal "Secure encryption of all data", t.rows[5][0]
    end

    should "open an XLSX with custom headers" do
      t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :headers => %w{foo bar baz})
      assert_equal "Secure encryption of all data", t.rows[5]['foo']
    end

    should "open an XLSX" do
      t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx')
      assert_equal "Secure encryption of all data", t.rows[5]["Requirements"]
    end
    
    should "work on filenames with spaces, using globbing" do
      t = RemoteTable.new :url => 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :glob => '/*.csv'
      assert_equal 'ASTON MARTIN', t.rows.first['MFR']
    end
    
    should "work on filenames with spaces" do
      t = RemoteTable.new :url => 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :filename => '2008_FE_guide_ALL_rel_dates_-no sales-for DOE-5-1-08.csv'
      assert_equal 'ASTON MARTIN', t.rows.first['MFR']
    end
    
    should "ignore UTF-8 byte order marks" do
      t = RemoteTable.new :url => 'http://www.freebase.com/type/exporttypeinstances/base/horses/horse_breed?page=0&filter_mode=type&filter_view=table&show%01p%3D%2Ftype%2Fobject%2Fname%01index=0&show%01p%3D%2Fcommon%2Ftopic%2Fimage%01index=1&show%01p%3D%2Fcommon%2Ftopic%2Farticle%01index=2&sort%01p%3D%2Ftype%2Fobject%2Ftype%01p%3Dlink%01p%3D%2Ftype%2Flink%2Ftimestamp%01index=false&=&exporttype=csv-8'
      assert_equal 'Tawleed', t.rows.first['name']
    end
    
    should "be able to apply errata files" do
      t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-G.htm",
                          :encoding => 'windows-1252',
                          :row_xpath => '//table/tr[2]/td/table/tr',
                          :column_xpath => 'td',
                          :errata => Errata.new(:table => RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'),
                                                :responder => AircraftGuru.new)
      g1 = t.rows.detect { |row| row['Model'] =~ /Gulfstream I/ }
      assert g1
      assert_equal 'GULFSTREAM AEROSPACE', g1['Manufacturer']
      assert_equal 'Gulfstream I', g1['Model']
    end

    # this will die with an error about libcurl if your curl doesn't support ssl
    should "connect using HTTPS if available" do
      t = RemoteTable.new(:url => 'https://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA')
      assert_equal 'Gulf Coast',     t.rows.first['PAD district name']
      assert_equal 'AL',             t.rows.first['State']
      assert_equal 'Rocky Mountain', t.rows.last['PAD district name']
      assert_equal 'WY',             t.rows.last['State']
    end
    
    should "read an HTML table made with frontpage" do
      t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-E.htm",
                          :encoding => 'US-ASCII',
                          :row_xpath => '//table/tr[2]/td/table/tr',
                          :column_xpath => 'td'
      assert_equal 'E110', t.rows.first['Designator']
      assert_equal 'EMBRAER', t.rows.first['Manufacturer']
      assert_equal 'EZKC', t.rows.last['Designator']
      assert_equal 'EZ King Cobra', t.rows.last['Model']
    end
  
    should "hash rows without paying attention to order" do
      x = ActiveSupport::OrderedHash.new
      x[:a] = 1
      x[:b] = 2
  
      y = ActiveSupport::OrderedHash.new
      y[:b] = 2
      y[:a] = 1
    
      assert_not_equal Marshal.dump(x), Marshal.dump(y)
      assert_equal RemoteTable::Transform.row_hash(x), RemoteTable::Transform.row_hash(y)
    end
  
    should "open a Google Docs url (as a CSV)" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA')
      assert_equal 'Gulf Coast',     t.rows.first['PAD district name']
      assert_equal 'AL',             t.rows.first['State']
      assert_equal 'Rocky Mountain', t.rows.last['PAD district name']
      assert_equal 'WY',             t.rows.last['State']
    end
    
    should "open a Google Docs url (as a CSV, with sheet options)" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA&single=true&gid=0')
      assert_equal 'Gulf Coast',     t.rows.first['PAD district name']
      assert_equal 'AL',             t.rows.first['State']
      assert_equal 'Rocky Mountain', t.rows.last['PAD district name']
      assert_equal 'WY',             t.rows.last['State']
    end
  
    should "open a Google Docs url as a CSV without headers" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA', :skip => 1, :headers => false)
      assert_equal 'AL',             t.rows.first[0]
      assert_equal 'Gulf Coast',     t.rows.first[4]
      assert_equal 'WY',             t.rows.last[0]
      assert_equal 'Rocky Mountain', t.rows.last[4]
    end
  
    should "take the last of values if the header is duplicated" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=tujrgUOwDSLWb-P4KCt1qBg')
      assert_equal '2', t.rows.first['dup_header']
    end
  
    should "respect field order in CSVs without headers" do
      t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA', :skip => 1, :headers => false)
      last_k = -1
      saw_string = false
      t.rows.each do |row|
        row.each do |k, v|
          if k.is_a?(Fixnum) and last_k.is_a?(Fixnum)
            assert !saw_string
            assert k > last_k
          end
          last_k = k
          saw_string = k.is_a?(String)
        end
      end
    end
  
    %w{ csv ods xls }.each do |format|
      eval %{
        should "read #{format}" do
          t = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.#{format}')
          # no blank headers
          assert t.rows.all? { |row| row.keys.all?(&:present?) }
          # correct values
          t.rows.each_with_index do |row, index|
            assert_equal row.except('row_hash'), @test2_rows[index]
          end
        end
      
        should "read #{format}, keeping blank rows" do
          t = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.#{format}', :keep_blank_rows => true)
          # no blank headers
          assert t.rows.all? { |row| row.keys.all?(&:present?) }
          # correct values
          t.rows.each_with_index do |row, index|
            assert_equal row.except('row_hash'), @test2_rows_with_blanks[index]
          end
        end
      }
    end
  
    should "read fixed width correctly" do
      t = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
                          :format => :fixed_width,
                          :skip => 1,
                          :schema => [[ 'header4', 10, { :type => :string }  ],
                                      [ 'spacer',  1 ],
                                      [ 'header5', 10, { :type => :string } ],
                                      [ 'spacer',  12 ],
                                      [ 'header6', 10, { :type => :string } ]])
  
      # no blank headers
      assert t.rows.all? { |row| row.keys.all?(&:present?) }
      # correct values
      t.rows.each_with_index do |row, index|
        assert_equal row.except('row_hash'), @test2_rows[index]
      end
    end
  
    should "read fixed width correctly, keeping blank rows" do
      t = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
                          :format => :fixed_width,
                          :keep_blank_rows => true,
                          :skip => 1,
                          :schema => [[ 'header4', 10, { :type => :string }  ],
                                      [ 'spacer',  1 ],
                                      [ 'header5', 10, { :type => :string } ],
                                      [ 'spacer',  12 ],
                                      [ 'header6', 10, { :type => :string } ]])
  
      # no blank headers
      assert t.rows.all? { |row| row.keys.all?(&:present?) }
      # correct values
      t.rows.each_with_index do |row, index|
        assert_equal row.except('row_hash'), @test2_rows_with_blanks[index]
      end
    end
  
    should "have the same row hash across formats" do
      csv = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.csv')
      ods = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.ods')
      xls = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.xls')
      fixed_width = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.fixed_width.txt',
                                    :format => :fixed_width,
                                    :skip => 1,
                                    :schema => [[ 'header1', 10, { :type => :string }  ],
                                                [ 'spacer',  1 ],
                                                [ 'header2', 10, { :type => :string } ],
                                                [ 'spacer',  12 ],
                                                [ 'header3', 10, { :type => :string } ]])
    
      csv2 = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.csv')
      ods2 = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.ods')
      xls2 = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.xls')
      fixed_width2 = RemoteTable.new(:url => 'http://cloud.github.com/downloads/seamusabshere/remote_table/remote_table_row_hash_test.alternate_order.fixed_width.txt',
                                     :format => :fixed_width,
                                     :skip => 1,
                                     :schema => [[ 'spacer',  11 ],
                                                 [ 'header2', 10, { :type => :string }  ],
                                                 [ 'spacer',  1 ],
                                                 [ 'header3', 10, { :type => :string } ],
                                                 [ 'spacer',  1 ],
                                                 [ 'header1', 10, { :type => :string } ]])
    
    
      reference = csv.rows[0]['row_hash']
  
      # same row hashes
      assert_equal reference, ods.rows[0]['row_hash']
      assert_equal reference, xls.rows[0]['row_hash']
      assert_equal reference, fixed_width.rows[0]['row_hash']
      # same row hashes with different order
      assert_equal reference, csv2.rows[0]['row_hash']
      assert_equal reference, ods2.rows[0]['row_hash']
      assert_equal reference, xls2.rows[0]['row_hash']
      assert_equal reference, fixed_width2.rows[0]['row_hash']
    end
  
    should "open an ODS" do
      t = RemoteTable.new(:url => 'http://www.worldmapper.org/data/opendoc/2_worldmapper_data.ods', :sheet => 'Data', :keep_blank_rows => true)
    
      assert_equal 'Central Africa', t.rows[5]['name']
      assert_equal 99,               t.rows[5]['MAP DATA population (millions) 2002'].to_i
    end
    
    should "open an XLS with a parser" do
      ma_1990_01 = {"month"=>1, "cost"=>"54.0", "locatable"=>"Massachusetts (State)", "year"=>1990}
      ga_1990_01 = {"month"=>1, "cost"=>"50.7", "locatable"=>"Georgia (State)", "year"=>1990}
  
      t = RemoteTable.new(:url => 'http://tonto.eia.doe.gov/dnav/pet/xls/PET_PRI_RESID_A_EPPR_PTA_CPGAL_M.xls',
                          :transform => { :class => FuelOilParser })
  
      assert t.rows.include?(ma_1990_01)
      assert t.rows.include?(ga_1990_01)
    end
  
    # should "provide a row_hash on demand" do
    #   t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/00data.zip',
    #                       :filename => 'Gd6-dsc.txt',
    #                       :format => :fixed_width,
    #                       :crop => 21..26, # inclusive
    #                       :cut => '2-',
    #                       :select => lambda { |row| /\A[A-Z]/.match row['code'] },
    #                       :schema => [[ 'code',   2, { :type => :string }  ],
    #                                   [ 'spacer', 2 ],
    #                                   [ 'name',   52, { :type => :string } ]])
    #   assert_equal 'a8a5d7f17b56772723c657eb62b0f238', t.rows.first['row_hash']
    # end
  end
end
