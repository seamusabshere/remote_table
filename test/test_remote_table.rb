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
  
  should "return an ordered hash" do
    t = RemoteTable.new 'http://spreadsheets.google.com/pub?key=tObVAGyqOkCBtGid0tJUZrw'
    assert_equal ::ActiveSupport::OrderedHash, t[0].class
  end
end
