require 'iconv'

class RemoteTable  
  class Format
    autoload :Excel, 'remote_table/format/excel'
    autoload :Excelx, 'remote_table/format/excelx'
    autoload :Delimited, 'remote_table/format/delimited'
    autoload :OpenOffice, 'remote_table/format/open_office'
    autoload :FixedWidth, 'remote_table/format/fixed_width'
    autoload :HTML, 'remote_table/format/html'
    autoload :XML, 'remote_table/format/xml'
    
    autoload :Textual, 'remote_table/format/mixins/textual'
    autoload :ProcessedByRoo, 'remote_table/format/mixins/processed_by_roo'
    autoload :ProcessedByNokogiri, 'remote_table/format/mixins/processed_by_nokogiri'
    
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
        str.encode! t.properties.external_encoding
      else
        str
      end
    end
    
    private
    
    def iconv
      @iconv ||= ::Iconv.new(t.properties.external_encoding_iconv, t.properties.internal_encoding)
    end
    
    include ::Enumerable
  end
end
