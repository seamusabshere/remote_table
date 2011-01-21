require 'helper'

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

class TestOldTransform < Test::Unit::TestCase
  should "open an XLS with a parser" do
    ma_1990_01 = {"month"=>1, "cost"=>"54.0", "locatable"=>"Massachusetts (State)", "year"=>1990}
    ga_1990_01 = {"month"=>1, "cost"=>"50.7", "locatable"=>"Georgia (State)", "year"=>1990}

    t = RemoteTable.new(:url => 'http://tonto.eia.doe.gov/dnav/pet/xls/PET_PRI_RESID_A_EPPR_PTA_CPGAL_M.xls',
                        :transform => { :class => FuelOilParser })
    assert t.rows.include?(ma_1990_01)
    assert t.rows.include?(ga_1990_01)
  end
end