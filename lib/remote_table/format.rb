if ::RUBY_VERSION >= '1.9'
  require 'ensure/encoding'
else
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
    
    def recode_as_utf8(raw_str)
      if ::RUBY_VERSION >= '1.9'
        $stderr.puts "[remote_table] Raw - #{raw_str}" if ::ENV['REMOTE_TABLE_DEBUG'] == 'true'
        recoded_str = raw_str.ensure_encoding 'UTF-8', :external_encoding => t.properties.encoding, :invalid_characters => :transcode
        $stderr.puts "[remote_table] Recoded - #{recoded_str}" if ::ENV['REMOTE_TABLE_DEBUG'] == 'true'
        recoded_str
      else
        $stderr.puts "[remote_table] Raw - #{raw_str}" if ::ENV['REMOTE_TABLE_DEBUG'] == 'true'
        recoded_str = ::Iconv.conv('UTF-8//TRANSLIT', t.properties.encoding[0], raw_str.to_s + ' ')[0..-2]
        $stderr.puts "[remote_table] Recoded - #{recoded_str}" if ::ENV['REMOTE_TABLE_DEBUG'] == 'true'
        recoded_str
      end
    end
    
    include ::Enumerable
    def each
      raise "must be defined by format"
    end
  end
end
