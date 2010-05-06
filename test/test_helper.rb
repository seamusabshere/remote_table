require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'ruby-debug'
require 'errata'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'remote_table'

class Test::Unit::TestCase
end
