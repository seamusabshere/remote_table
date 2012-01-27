class RemoteTable
  class Format
    module ProcessedByNokogiri
      def each
        require 'nokogiri'
        require 'cgi'
        
        raise ::ArgumentError, "Need :row_css or :row_xpath in order to process XML or HTML" unless t.config.row_css or t.config.row_xpath
        remove_useless_characters!
        transliterate_whole_file_to_utf8!
        
        headers = t.config.headers

        xml = nokogiri_class.parse(unescaped_xml_without_soft_hyphens, nil, 'UTF-8')
        (row_css? ? xml.css(t.config.row_css) : xml.xpath(t.config.row_xpath)).each do |row|
          values = if column_css?
            row.css(t.config.column_css)
          elsif column_xpath?
            row.xpath(t.config.column_xpath)
          else
            [row]
          end.map { |cell| assume_utf8 cell.content.gsub(/\s+/, ' ').strip }
          if headers == :first_row
            headers = values.select(&:present?)
            next
          end
          output = if t.config.output_class == ::Array
            values
          else
            zip headers, values
          end
          if t.config.keep_blank_rows or values.any?
            yield output
          end
        end
      ensure
        t.local_file.cleanup
      end

      private

      def row_css?
        !!t.config.row_css
      end
      
      def column_css?
        !!t.config.column_css
      end
      
      def column_xpath?
        !!t.config.column_xpath
      end
      
      # http://snippets.dzone.com/posts/show/406
      def zip(keys, values)
        hash = ::ActiveSupport::OrderedHash.new
        keys.zip(values) { |k,v| hash[k]=v }
        hash
      end

      # should we be doing this in ruby?
      def unescaped_xml_without_soft_hyphens
        str = ::CGI.unescapeHTML t.local_file.encoded_io.read
        # get rid of MS Office baddies
        str.gsub! '&shy;', ''
        str
      end
    end
  end
end
