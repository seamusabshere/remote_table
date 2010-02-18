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
    row.keys.grep(/(.*) Residual Fuel Oil/) do |location_column_name|
      next if (cost = row[location_column_name]).blank? or (date = row['Date']).blank?
      if $1.starts_with?('U.S.')
        locatable = "united_states (Country)"
      elsif $1.include?('PADD')
        /\(PADD (.*)\)/.match($1)
        next if $1 == '1' # skip PADD 1 because we always prefer subdistricts
        locatable = "#{$1} (PetroleumAdministrationForDefenseDistrict)"
      else
        locatable = "#{$1} (State)"
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
  
  should "hash rows without paying attention to order" do
    x = ActiveSupport::OrderedHash.new
    x[:a] = 1
    x[:b] = 2
  
    y = ActiveSupport::OrderedHash.new
    y[:b] = 2
    y[:a] = 1
    
    assert Marshal.dump(x) != Marshal.dump(y)
    assert RemoteTable::Transform.row_hash(x) == RemoteTable::Transform.row_hash(y)
  end
  
  should "open a Google Docs url (as a CSV)" do
    t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA')
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
  
  should "open an XLS with a parser" do
    ma_1990_01 = {"month"=>1, "cost"=>"54.0", "locatable"=>"Massachusetts (State)", "year"=>1990}
    ga_1990_01 = {"month"=>1, "cost"=>"50.7", "locatable"=>"Georgia (State)", "year"=>1990}
  
    t = RemoteTable.new(:url => 'http://tonto.eia.doe.gov/dnav/pet/xls/PET_PRI_RESID_A_EPPR_PTA_CPGAL_M.xls',
                        :transform => { :class => FuelOilParser })
    assert t.rows.include?(ma_1990_01)
    assert t.rows.include?(ga_1990_01)
  end
  
  should "provide a row_hash on demand" do
    t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/00data.zip',
                        :filename => 'Gd6-dsc.txt',
                        :format => :fixed_width,
                        :crop => 21..26, # inclusive
                        :cut => '2-',
                        :select => lambda { |row| /\A[A-Z]/.match row['code'] },
                        :schema => [[ 'code',   2, { :type => :string }  ],
                                    [ 'spacer', 2 ],
                                    [ 'name',   52, { :type => :string } ]])
    assert_equal 'a8a5d7f17b56772723c657eb62b0f238', t.rows.first['row_hash']
  end
end
