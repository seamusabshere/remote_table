require 'nokogiri'
require 'cgi'
class RemoteTable
  class Format
    class XML < Format
      include Textual
      include ProcessedByNokogiri
      
      def nokogiri_class
        ::Nokogiri::XML::Document
      end
    end
  end
end
