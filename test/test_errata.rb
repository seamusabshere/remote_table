require 'helper'
require 'errata'

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

describe RemoteTable do
  describe "when using an errata file" do
    it "be able to apply Errata instances directly" do
      t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-G.htm",
                          :encoding => 'windows-1252',
                          :row_xpath => '//table[2]//table[1]//tr[3]//tr',
                          :column_xpath => 'td',
                          :errata => Errata.new(:url => 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw',
                                                :responder => AircraftGuru.new)
      g1 = t.rows.detect { |row| row['Model'] =~ /Gulfstream I/ }
      g1.wont_be_nil
      g1['Manufacturer'].must_equal 'GULFSTREAM AEROSPACE'
      g1['Model'].must_equal 'Gulfstream I'
    end
    
    it "be able to apply erratas given a hash of options" do
      t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-G.htm",
                          :encoding => 'windows-1252',
                          :row_xpath => '//table[2]//table[1]//tr[3]//tr',
                          :column_xpath => 'td',
                          :errata => { :url => 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw',
                                       :responder => AircraftGuru.new }
      g1 = t.rows.detect { |row| row['Model'] =~ /Gulfstream I/ }
      g1.wont_be_nil
      g1['Manufacturer'].must_equal 'GULFSTREAM AEROSPACE'
      g1['Model'].must_equal 'Gulfstream I'
    end
  end
end
