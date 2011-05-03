# encoding: utf-8
require 'helper'

class TestRemoteTable < Test::Unit::TestCase
  should "open an XLSX" do
    t = RemoteTable.new 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx'
    assert_equal "Secure encryption of all data", t[5]["Requirements"]
  end
  
  should "add a row hash to every row" do
    t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx')
    assert_equal "06d8a738551c17735e2731e25c8d0461", t[5]['row_hash']
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
    assert_equal Array, t.instance_variable_get(:@to_a).class
    t.free
    assert_equal NilClass, t.instance_variable_get(:@to_a).class
  end
  
  # fixes ArgumentError: invalid byte sequence in UTF-8
  should %{safely strip soft hyphens and read non-utf8 html} do
    t = RemoteTable.new :url => "http://www.faa.gov/air_traffic/publications/atpubs/CNT/5-2-A.htm", :encoding => 'windows-1252', :row_xpath => '//table/tr[2]/td/table/tr', :column_xpath => 'td'
    assert t.rows.detect { |row| row['Model'] == 'A300B4600' }
  end
  
  should %{transliterate characters into UTF-8 as long as the user provides the right encoding} do
    t = RemoteTable.new :url => 'http://static.brighterplanet.com/science/data/consumables/pets/breed_genders.csv', :encoding => 'ISO-8859-1'
    assert t.rows.detect { |row| row['name'] == 'Briquet Griffon Vendéen' }
  end
end
