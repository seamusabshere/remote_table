require 'helper'

describe RemoteTable do
  describe "when dealing with large files" do
    it "open an XLS inside a zip file" do
      t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/02data.zip', :filename => 'guide_jan28.xls')
      t.rows.first['Manufacturer'].must_equal 'ACURA'
      t.rows.first['carline name'].must_equal 'NSX'
      t.rows.last['Manufacturer'].must_equal 'VOLVO'
      t.rows.last['carline name'].must_equal 'V70 XC AWD'
    end

    it "not have indifferent string/symbol hash access" do
      t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/02data.zip', :filename => 'guide_jan28.xls')
      t.rows.first['Manufacturer'].must_equal 'ACURA'
      t.rows.first[:Manufacturer].must_equal nil
    end

    it "open a CSV inside a zip file" do
      t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/98guide6.zip', :filename => '98guide6.csv')
      t.rows.length.must_equal 806
      t.rows.first['Manufacturer'].must_equal 'ACURA'
      t.rows.first['carline name'].must_equal 'NSX'
      t.rows.last['Manufacturer'].must_equal 'TOYOTA'
      t.rows.last['carline name'].must_equal 'RAV4 SOFT TOP 4WD'
    end

    it "open a fixed-width file with an inline schema inside a zip file" do
      t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/00data.zip',
                          :filename => 'Gd6-dsc.txt',
                          :format => :fixed_width,
                          :crop => 21..26, # inclusive
                          :cut => '2-',
                          :select => proc { |row| /\A[A-Z]/.match row['code'] },
                          :schema => [[ 'code',   2, { :type => :string }  ],
                                      [ 'spacer', 2 ],
                                      [ 'name',   52, { :type => :string } ]])
      t.rows.first['name'].must_equal 'regular grade gasoline (octane number of 87)'
      t.rows.first['code'].must_equal 'R'
      t.rows.last['name'].must_equal 'electricity'
      t.rows.last['code'].must_equal 'El'
    end

    it "send form data, follow redirects and use a filename glob" do
      url = 'http://www.transtats.bts.gov/DownLoad_Table.asp?Table_ID=293&Has_Group=3&Is_Zipped=0'
      form_data = 'UserTableName=T_100_Segment__All_Carriers&DBShortName=Air_Carriers&RawDataTable=T_T100_SEGMENT_ALL_CARRIER&sqlstr=+SELECT+DEPARTURES_SCHEDULED%2CDEPARTURES_PERFORMED%2CPAYLOAD%2CSEATS%2CPASSENGERS%2CFREIGHT%2CMAIL%2CDISTANCE%2CRAMP_TO_RAMP%2CAIR_TIME%2CUNIQUE_CARRIER%2CAIRLINE_ID%2CUNIQUE_CARRIER_NAME%2CUNIQUE_CARRIER_ENTITY%2CREGION%2CCARRIER%2CCARRIER_NAME%2CCARRIER_GROUP%2CCARRIER_GROUP_NEW%2CORIGIN%2CORIGIN_CITY_NAME%2CORIGIN_STATE_ABR%2CORIGIN_STATE_FIPS%2CORIGIN_STATE_NM%2CORIGIN_COUNTRY%2CORIGIN_COUNTRY_NAME%2CORIGIN_WAC%2CDEST%2CDEST_CITY_NAME%2CDEST_STATE_ABR%2CDEST_STATE_FIPS%2CDEST_STATE_NM%2CDEST_COUNTRY%2CDEST_COUNTRY_NAME%2CDEST_WAC%2CAIRCRAFT_GROUP%2CAIRCRAFT_TYPE%2CAIRCRAFT_CONFIG%2CYEAR%2CQUARTER%2CMONTH%2CDISTANCE_GROUP%2CCLASS%2CDATA_SOURCE+FROM++T_T100_SEGMENT_ALL_CARRIER+WHERE+Month+%3D1+AND+YEAR%3D2008&varlist=DEPARTURES_SCHEDULED%2CDEPARTURES_PERFORMED%2CPAYLOAD%2CSEATS%2CPASSENGERS%2CFREIGHT%2CMAIL%2CDISTANCE%2CRAMP_TO_RAMP%2CAIR_TIME%2CUNIQUE_CARRIER%2CAIRLINE_ID%2CUNIQUE_CARRIER_NAME%2CUNIQUE_CARRIER_ENTITY%2CREGION%2CCARRIER%2CCARRIER_NAME%2CCARRIER_GROUP%2CCARRIER_GROUP_NEW%2CORIGIN%2CORIGIN_CITY_NAME%2CORIGIN_STATE_ABR%2CORIGIN_STATE_FIPS%2CORIGIN_STATE_NM%2CORIGIN_COUNTRY%2CORIGIN_COUNTRY_NAME%2CORIGIN_WAC%2CDEST%2CDEST_CITY_NAME%2CDEST_STATE_ABR%2CDEST_STATE_FIPS%2CDEST_STATE_NM%2CDEST_COUNTRY%2CDEST_COUNTRY_NAME%2CDEST_WAC%2CAIRCRAFT_GROUP%2CAIRCRAFT_TYPE%2CAIRCRAFT_CONFIG%2CYEAR%2CQUARTER%2CMONTH%2CDISTANCE_GROUP%2CCLASS%2CDATA_SOURCE&grouplist=&suml=&sumRegion=&filter1=title%3D&filter2=title%3D&geo=All%A0&time=January&timename=Month&GEOGRAPHY=All&XYEAR=2008&FREQUENCY=1&AllVars=All&VarName=DEPARTURES_SCHEDULED&VarDesc=DepScheduled&VarType=Num&VarName=DEPARTURES_PERFORMED&VarDesc=DepPerformed&VarType=Num&VarName=PAYLOAD&VarDesc=Payload&VarType=Num&VarName=SEATS&VarDesc=Seats&VarType=Num&VarName=PASSENGERS&VarDesc=Passengers&VarType=Num&VarName=FREIGHT&VarDesc=Freight&VarType=Num&VarName=MAIL&VarDesc=Mail&VarType=Num&VarName=DISTANCE&VarDesc=Distance&VarType=Num&VarName=RAMP_TO_RAMP&VarDesc=RampToRamp&VarType=Num&VarName=AIR_TIME&VarDesc=AirTime&VarType=Num&VarName=UNIQUE_CARRIER&VarDesc=UniqueCarrier&VarType=Char&VarName=AIRLINE_ID&VarDesc=AirlineID&VarType=Num&VarName=UNIQUE_CARRIER_NAME&VarDesc=UniqueCarrierName&VarType=Char&VarName=UNIQUE_CARRIER_ENTITY&VarDesc=UniqCarrierEntity&VarType=Char&VarName=REGION&VarDesc=CarrierRegion&VarType=Char&VarName=CARRIER&VarDesc=Carrier&VarType=Char&VarName=CARRIER_NAME&VarDesc=CarrierName&VarType=Char&VarName=CARRIER_GROUP&VarDesc=CarrierGroup&VarType=Num&VarName=CARRIER_GROUP_NEW&VarDesc=CarrierGroupNew&VarType=Num&VarName=ORIGIN&VarDesc=Origin&VarType=Char&VarName=ORIGIN_CITY_NAME&VarDesc=OriginCityName&VarType=Char&VarName=ORIGIN_STATE_ABR&VarDesc=OriginState&VarType=Char&VarName=ORIGIN_STATE_FIPS&VarDesc=OriginStateFips&VarType=Char&VarName=ORIGIN_STATE_NM&VarDesc=OriginStateName&VarType=Char&VarName=ORIGIN_COUNTRY&VarDesc=OriginCountry&VarType=Char&VarName=ORIGIN_COUNTRY_NAME&VarDesc=OriginCountryName&VarType=Char&VarName=ORIGIN_WAC&VarDesc=OriginWac&VarType=Num&VarName=DEST&VarDesc=Dest&VarType=Char&VarName=DEST_CITY_NAME&VarDesc=DestCityName&VarType=Char&VarName=DEST_STATE_ABR&VarDesc=DestState&VarType=Char&VarName=DEST_STATE_FIPS&VarDesc=DestStateFips&VarType=Char&VarName=DEST_STATE_NM&VarDesc=DestStateName&VarType=Char&VarName=DEST_COUNTRY&VarDesc=DestCountry&VarType=Char&VarName=DEST_COUNTRY_NAME&VarDesc=DestCountryName&VarType=Char&VarName=DEST_WAC&VarDesc=DestWac&VarType=Num&VarName=AIRCRAFT_GROUP&VarDesc=AircraftGroup&VarType=Num&VarName=AIRCRAFT_TYPE&VarDesc=AircraftType&VarType=Char&VarName=AIRCRAFT_CONFIG&VarDesc=AircraftConfig&VarType=Num&VarName=YEAR&VarDesc=Year&VarType=Num&VarName=QUARTER&VarDesc=Quarter&VarType=Num&VarName=MONTH&VarDesc=Month&VarType=Num&VarName=DISTANCE_GROUP&VarDesc=DistanceGroup&VarType=Num&VarName=CLASS&VarDesc=Class&VarType=Char&VarName=DATA_SOURCE&VarDesc=DataSource&VarType=Char'
      t = RemoteTable.new :url => url, :form_data => form_data, :compression => :zip, :glob => '/*.csv'
      t.rows.first['DEST_COUNTRY_NAME'].must_equal 'United States'
    end
  end
end
