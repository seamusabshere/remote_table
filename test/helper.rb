require 'bundler/setup'

require 'minitest/autorun'
# require 'pry-rescue/minitest'
require 'remote_table'

class MiniTest::Spec
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
