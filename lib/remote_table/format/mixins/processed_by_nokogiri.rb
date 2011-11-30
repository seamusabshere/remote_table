require 'nokogiri'
require 'cgi'
class RemoteTable
  class Format
    module ProcessedByNokogiri
      def each
        raise "[remote_table] Need :row_css or :row_xpath in order to process XML or HTML" unless t.properties.row_css or t.properties.row_xpath
        remove_useless_characters!
        transliterate_whole_file_to_utf8!
        first_row = true
        keys = t.properties.headers if t.properties.headers.is_a?(::Array)
        xml = nokogiri_class.parse(unescaped_xml_without_soft_hyphens, nil, 'UTF-8')
        (row_css? ? xml.css(t.properties.row_css) : xml.xpath(t.properties.row_xpath)).each do |row|
          values = if column_css?
            row.css(t.properties.column_css)
          elsif column_xpath?
            row.xpath(t.properties.column_xpath)
          else
            [row]
          end.map { |cell| assume_utf8 cell.content.gsub(/\s+/, ' ').strip }
          if first_row and t.properties.use_first_row_as_header?
            keys = values
            first_row = false
            next
          end
          output = if t.properties.output_class == ::Array
            values
          else
            zip keys, values
          end
          if t.properties.keep_blank_rows or values.any?
            yield output
          end
        end
      ensure
        t.local_file.cleanup
      end

      private

      def row_css?
        !!t.properties.row_css
      end
      
      def column_css?
        !!t.properties.column_css
      end
      
      def column_xpath?
        !!t.properties.column_xpath
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
