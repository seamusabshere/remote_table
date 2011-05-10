require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'shoulda'
require 'ruby-debug'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'remote_table'))

class Test::Unit::TestCase
  def setup
    if RUBY_VERSION >= '1.9'
      @old_default_internal = Encoding.default_internal
      @old_default_external = Encoding.default_external
      # totally random choices here
      Encoding.default_internal = 'EUC-JP'
      Encoding.default_external = 'Shift_JIS'
    end
  end
  
  def teardown
    if RUBY_VERSION >= '1.9'
      Encoding.default_internal = @old_default_internal
      Encoding.default_external = @old_default_external
    end
  end
end
