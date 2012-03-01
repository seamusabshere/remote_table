class RemoteTable
  class Format
    module ProcessedByRoo
      def each(&blk)
        require 'iconv'
        require 'roo'

        spreadsheet = roo_class.new t.local_file.path, nil, :ignore
        spreadsheet.default_sheet = t.config.sheet.is_a?(::Numeric) ? spreadsheet.sheets[t.config.sheet] : t.config.sheet
        
        first_row = if t.config.crop
          t.config.crop.first + 1
        else
          t.config.skip + 1
        end
          
        last_row = if t.config.crop
          t.config.crop.last
        else
          spreadsheet.last_row
        end
        
        if t.config.output_class == ::Array
          (first_row..last_row).each do |y|
            output = (1..spreadsheet.last_column).map do |x|
              assume_utf8 spreadsheet.cell(y, x).to_s.gsub(/<[^>]+>/, '').strip
            end
            yield output if t.config.keep_blank_rows or output.any? { |v| v.present? }
          end
        else
          headers = {}
          if t.config.use_first_row_as_header?
            (1..spreadsheet.last_column).each do |x|
              v = spreadsheet.cell(first_row, x)
              v = spreadsheet.cell(first_row - 1, x) if v.blank? # look up
              if v.present?
                v = assume_utf8 v
                headers[v] = x # 'foobar' is found at column 6
              end
            end
            # "advance the cursor"
            first_row += 1
          else
            t.config.headers.each_with_index do |k, i|
              headers[k] = i + 1
            end
          end
          (first_row..last_row).each do |y|
            output = ::ActiveSupport::OrderedHash.new
            headers.each do |k, x|
              output[k] = assume_utf8 spreadsheet.cell(y, x).to_s.gsub(/<[^>]+>/, '').strip
            end
            yield output if t.config.keep_blank_rows or output.any? { |k, v| v.present? }
          end
        end
      ensure
        t.local_file.cleanup
      end
    end
  end
end
