require 'roo'
class RemoteTable
  class Format
    module ProcessedByRoo
      def each(&blk)
        spreadsheet = roo_class.new t.local_file.path, nil, :ignore
        spreadsheet.default_sheet = t.properties.sheet.is_a?(::Numeric) ? spreadsheet.sheets[t.properties.sheet] : t.properties.sheet
        if t.properties.output_class == ::Array
          (first_row..spreadsheet.last_row).each do |y|
            output = (1..spreadsheet.last_column).map do |x|
              assume_utf8 spreadsheet.cell(y, x).to_s.gsub(/<[^>]+>/, '').strip
            end
            yield output if t.properties.keep_blank_rows or output.any? { |v| v.present? }
          end
        else
          keys = {}
          if t.properties.use_first_row_as_header?
            (1..spreadsheet.last_column).each do |x|
              keys[x] = spreadsheet.cell(first_row, x)
              keys[x] = spreadsheet.cell(first_row - 1, x) if keys[x].blank? # look up
              keys[x] = assume_utf8 keys[x]
            end
          else
            (1..spreadsheet.last_column).each do |x|
              keys[x] = assume_utf8 t.properties.headers[x - 1]
            end
          end
          (first_row+1..spreadsheet.last_row).each do |y|
            output = (1..spreadsheet.last_column).inject(::ActiveSupport::OrderedHash.new) do |memo, x|
              if keys[x].present?
                memo[keys[x]] = assume_utf8 spreadsheet.cell(y, x).to_s.gsub(/<[^>]+>/, '').strip
              end
              memo
            end
            yield output if t.properties.keep_blank_rows or output.any? { |k, v| v.present? }
          end
        end
      ensure
        t.local_file.cleanup
      end

      private

      def first_row
        1 + t.properties.skip
      end
    end
  end
end
