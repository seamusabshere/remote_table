# encoding: utf-8
require 'helper'

class TestRemoteTable < Test::Unit::TestCase
  should "open an XLSX" do
    t = RemoteTable.new 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx'
    assert_equal "Secure encryption of all data", t[5]["Requirements"]
  end
  
  should "add a row hash to every row" do
    t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx')
    assert_equal "06d8a738551c17735e2731e25c8d0461", t[5].row_hash
  end
  
  should "open a google doc" do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    assert_equal 'Seamus Abshere', t[0]['name']
  end
  
  should "open a csv with custom headers" do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw', :headers => %w{ col1 col2 col3 }
    assert_equal 'name', t[0]['col2']
    assert_equal 'Seamus Abshere', t[1]['col2']
  end
  
  should "return an ordered hash" do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    assert_equal ::ActiveSupport::OrderedHash, t[0].class
  end
  
  should "pass through fastercsv options" do
    f = Tempfile.new 'pass-through-fastercsv-options'
    f.write %{3,Title example,Body example with a <a href="">link</a>,test category}
    f.flush
    t = RemoteTable.new "file://#{f.path}", :quote_char => %{'}, :headers => nil
    assert_equal %{Body example with a <a href="">link</a>}, t[0][2]
    f.close
  end
  
  should "open a csv inside a zip file" do
    t = RemoteTable.new  'http://www.epa.gov/climatechange/emissions/downloads10/2010-Inventory-Annex-Tables.zip',
                         :filename => 'Annex Tables/Annex 3/Table A-93.csv',
                         :skip => 1,
                         :select => lambda { |row| row['Vehicle Age'].to_i.to_s == row['Vehicle Age'] }
    assert_equal '9.09%', t[0]['LDGV']
  end
  
  should 'not blow up if each is called twice' do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    assert_nothing_raised do
      t.each { |row| }
      t.each { |row| }
    end
  end
  
  should 'allow itself to be cleared for save memory' do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    t.to_a
    assert t.send(:cache).length > 0
    t.free
    assert t.send(:cache).length == 0
  end
    
  # fixes ArgumentError: invalid byte sequence in UTF-8
  should %{safely strip soft hyphens and read windows-1252 html} do
    t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-A.htm", :row_xpath => '//table/tr[2]/td/table/tr', :column_xpath => 'td'
    assert t.rows.detect { |row| row['Model'] == 'A300B4600' }
  end
  
  should %{transliterate characters from ISO-8859-1} do
    t = RemoteTable.new :url => 'http://static.brighterplanet.com/science/data/consumables/pets/breed_genders.csv'
    assert t.rows.detect { |row| row['name'] == 'Briquet Griffon Vendéen' }
  end
  
  should %{read xml with css selectors} do
    t = RemoteTable.new 'http://www.nanonull.com/TimeService/TimeService.asmx/getCityTime?city=Chicago', :format => :xml, :row_css => 'string', :headers => false
    assert /(AM|PM)/.match(t[0][0])
  end
  
  should %{optionally stream rows instead of caching them} do
    t = RemoteTable.new 'http://www.earthtools.org/timezone/40.71417/-74.00639', :format => :xml, :row_xpath => '//timezone/isotime', :headers => false, :streaming => true
    time1 = t[0][0]
    assert /\d\d\d\d-\d\d-\d\d/.match(time1)
    sleep 1
    time2 = t[0][0]
    assert(time1 != time2)
  end
  
  should %{not die when it reads Åland Islands} do
    t = RemoteTable.new 'http://www.iso.org/iso/list-en1-semic-3.txt', :skip => 2, :headers => false, :delimiter => ';'
    assert_nothing_raised do
      t[1][0]
    end
  end
  
  should %{parse a big CSV that is not UTF-8} do
    t = RemoteTable.new 'https://openflights.svn.sourceforge.net/svnroot/openflights/openflights/data/airports.dat', :headers => false
    assert_equal 'Goroka', t[0][1]
  end
end
