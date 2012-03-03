require 'iconv'

require 'remote_table/format/mixins/textual'
require 'remote_table/format/mixins/processed_by_roo'
require 'remote_table/format/mixins/processed_by_nokogiri'
require 'remote_table/format/excel'
require 'remote_table/format/excelx'
require 'remote_table/format/delimited'
require 'remote_table/format/open_office'
require 'remote_table/format/fixed_width'
require 'remote_table/format/html'
require 'remote_table/format/xml'
require 'remote_table/format/yaml'
class RemoteTable  
  class Format
    
    attr_reader :t

    def initialize(t)
      @t = t
    end
    
    def transliterate_to_utf8(str)
      if str.is_a?(::String)
        [ iconv.iconv(str), iconv.iconv(nil) ].join
      end
    end

    def assume_utf8(str)
      if str.is_a?(::String) and ::RUBY_VERSION >= '1.9'
        str.encode! t.config.external_encoding
      else
        str
      end
    end
    
    private
    
    def iconv
      @iconv ||= ::Iconv.new(t.config.external_encoding_iconv, t.config.internal_encoding)
    end
    
    include ::Enumerable
  end
end
