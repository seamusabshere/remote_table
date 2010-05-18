class RemoteTable
  module Html
    def each_row(&block)
      backup_file!
      convert_file_to_utf8!
      html_headers = (headers.is_a?(Array)) ? headers : nil
      Nokogiri::HTML(unescaped_html_without_soft_hyphens, nil, 'UTF-8').xpath(row_xpath).each do |row|
        values = row.xpath(column_xpath).map { |td| td.content.gsub(/\s+/, ' ').strip }
        if html_headers.nil?
          html_headers = values
          next
        end
        hash = zip html_headers, values
        yield hash if keep_blank_rows or hash.any? { |k, v| v.present? }
      end
    ensure
      restore_file!
    end

    private
    
    # http://snippets.dzone.com/posts/show/406
    def zip(keys, values)
      hash = Hash.new
      keys.zip(values) { |k,v| hash[k]=v }
      hash
    end
    
    # should we be doing this in ruby?
    def unescaped_html_without_soft_hyphens
      str = CGI.unescapeHTML IO.read(path)
      str.gsub! /&shy;|\302\255/, ''
      str
    end
  end
end
