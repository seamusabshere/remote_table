# encoding: utf-8
require 'helper'

describe RemoteTable do
  describe 'used on local files' do
    it "understands relative paths" do
      RemoteTable.new('test/data/color.csv').to_a.must_equal RemoteTable.new(File.expand_path('../../test/data/color.csv', __FILE__)).to_a
    end
  end
end
