# encoding: utf-8
require 'helper'

describe RemoteTable do
  it "has a transpose helper" do
    t = RemoteTable.transpose('test/support/color.csv', 'en', 'es')
    t['red'].must_equal 'rojo'
    t = RemoteTable.transpose('test/support/color.csv', 'ru', 'en')
    t['зеленый'].must_equal 'green'
  end
end
