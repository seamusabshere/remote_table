if ::RUBY_VERSION >= '1.9'
  require 'ensure/encoding'
else
  $KCODE = 'U'
  require 'iconv'
end

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
    
    def utf8(str)
      if ::RUBY_VERSION >= '1.9'
        str.ensure_encoding 'UTF-8', :external_encoding => t.properties.encoding, :invalid_characters => :transcode
      else
        return str if t.properties.encoding[0] =~ /utf.?8/i
        begin
          ::Iconv.conv('UTF-8//TRANSLIT', t.properties.encoding[0], str.to_s + ' ')[0..-2]
        rescue ::Iconv::IllegalSequence
          $stderr.puts "[remote_table] Unable to transliterate #{str} into UTF-8 given #{t.properties.encoding[0]}"
          str
        end
      end
    end
    
    include ::Enumerable
    def each
      raise "must be defined by format"
    end
  end
end
