require 'helper'

class NaturalGasParser
  def initialize(options = {})
    # nothing
  end
  def apply(row)
    virtual_rows = []
    row.keys.grep(/\A(.*) Natural Gas/) do |location_column_name|
      match_1 = $1
      next if (price = row[location_column_name]).blank? or (date = row['Date']).blank?
      if match_1 == 'U.S.'
        locatable_id = 'US'
        locatable_type = 'Country'
      else
        locatable_id = match_1 # name
        locatable_type = 'State'
      end
      date = Time.parse(date)
      new_row = ActiveSupport::OrderedHash.new
      new_row['locatable_id'] = locatable_id
      new_row['locatable_type'] = locatable_type
      new_row['price'] = price
      new_row['year'] = date.year
      new_row['month'] = date.month
      row_hash = RemoteTable::Transform.row_hash new_row
      new_row['row_hash'] = row_hash
      virtual_rows << new_row
    end
    virtual_rows
  end
end

class TestOldTransform < Test::Unit::TestCase
  should "open an XLS with a parser" do
    t = RemoteTable.new(:url => 'http://tonto.eia.doe.gov/dnav/ng/xls/ng_pri_sum_a_EPG0_FWA_DMcf_a.xls',
           :sheet => 'Data 1',
           :skip => 2,
           :select => lambda { |row| row['year'].to_i > 1989 },
           :transform => { :class => NaturalGasParser })
    assert_equal 'Country', t[0]['locatable_type']
    assert_equal 'US', t[0]['locatable_id']
    assert(t[0].row_hash.present?)
  end
end
