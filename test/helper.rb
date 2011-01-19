require 'rubygems'
require 'test/unit'
require 'shoulda'
# require 'ruby-debug'
require 'errata'
require 'active_support/all'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'remote_table'))

class Test::Unit::TestCase
end
