require 'test_helper'

class FuelOilParser
  def initialize(options = {})
    # nothing
  end
  def add_hints!(bus)
    bus[:sheet] = 'Data 1'
    bus[:skip] = 2
    bus[:select] = lambda { |row| row[:year] > 1989 }
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
      virtual_rows << HashWithIndifferentAccess.new(
        :locatable => locatable,
        :cost => cost,
        :year => date.year,
        :month => date.month
      )
    end
    virtual_rows
  end
end

class RemoteTableTest < Test::Unit::TestCase
  should "open an XLS inside a zip file" do
    t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/02data.zip', :filename => 'guide_jan28.xls')
    assert_equal 'ACURA',      t.rows.first['Manufacturer']
    assert_equal 'NSX',        t.rows.first['carline name']
    assert_equal 'VOLVO',      t.rows.last['Manufacturer']
    assert_equal 'V70 XC AWD', t.rows.last['carline name']
  end
  
  should "have indifferent hash access" do
    t = RemoteTable.new(:url => 'http://www.fueleconomy.gov/FEG/epadata/02data.zip', :filename => 'guide_jan28.xls')
    assert_equal 'ACURA',      t.rows.first['Manufacturer'.to_sym]
    assert_equal 'NSX',        t.rows.first['carline name'.to_sym]
    assert_equal 'VOLVO',      t.rows.last['Manufacturer'.to_sym]
    assert_equal 'V70 XC AWD', t.rows.last['carline name'.to_sym]
  end
  
  should "open a Google Docs url" do
    t = RemoteTable.new(:url => 'http://spreadsheets.google.com/pub?key=t5HM1KbaRngmTUbntg8JwPA')
    assert_equal 'Gulf Coast',     t.rows.first['PAD district name']
    assert_equal 'AL',             t.rows.first['State']
    assert_equal 'Rocky Mountain', t.rows.last['PAD district name']
    assert_equal 'WY',             t.rows.last['State']
  end
  
  should "open an ODS" do
    t = RemoteTable.new(:url => 'http://static.brighterplanet.com/science/profiler/footprint_model.ods', :sheet => 'Export')
    assert_equal 'automobiles', t.rows.first['component']
    assert_equal 2005.0,        t.rows.first['period'].to_f
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
                        :select => lambda { |row| /\A[A-Z]/.match row[:code] },
                        :schema => [[ :code,   2, { :type => :string }  ],
                                    [ :spacer, 2 ],
                                    [ :name,   52, { :type => :string } ]])
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
    assert_equal ma_1990_01, t.rows[0]
    assert_equal ga_1990_01, t.rows[1]
  end
end
