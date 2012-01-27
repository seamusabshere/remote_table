class RemoteTable
  class Format
    class HTML < Format
      include Textual
      include ProcessedByNokogiri
      
      def nokogiri_class
        ::Nokogiri::HTML::Document
      end
    end
  end
end
