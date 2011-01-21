require 'helper'

class TestRemoteTable < Test::Unit::TestCase
  should "add a row hash to every row" do
    t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx')
    assert_equal "59d68cfc1cd6b32f5b333d6f0e4bea6d", t[5]['row_hash']
  end
end
