require 'nokogiri'
require 'cgi'
class RemoteTable
  class Format
    class HTML < Format
      include Textual
      def each(&blk)
        remove_useless_characters!
        html_headers = (t.properties.headers.is_a?(::Array)) ? t.properties.headers : nil
        ::Nokogiri::HTML(unescaped_html_without_soft_hyphens, nil, 'UTF-8').xpath(t.properties.row_xpath).each do |row|
          values = row.xpath(t.properties.column_xpath).map { |td| td.content.gsub(/\s+/, ' ').strip }
          if html_headers.nil?
            html_headers = values
            next
          end
          hash = zip html_headers, values
          yield hash if t.properties.keep_blank_rows or hash.any? { |k, v| v.present? }
        end
      ensure
        t.local_file.delete
      end

      private

      # http://snippets.dzone.com/posts/show/406
      def zip(keys, values)
        hash = ::Hash.new
        keys.zip(values) { |k,v| hash[k]=v }
        hash
      end

      # should we be doing this in ruby?
      def unescaped_html_without_soft_hyphens
        str = ::CGI.unescapeHTML utf8(::IO.read(t.local_file.path))
        # get rid of MS Office baddies
        str.gsub! '&shy;', ''
        str
      end
    end
  end
end
