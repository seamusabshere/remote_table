require 'helper'

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

class TestErrata < Test::Unit::TestCase
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
end
