require 'roo'
class RemoteTable
  class Format
    module Rooable
      def each(&blk)
        spreadsheet = roo_class.new t.local_file.path, nil, :ignore
        spreadsheet.default_sheet = t.properties.sheet.is_a?(::Numeric) ? spreadsheet.sheets[t.properties.sheet] : t.properties.sheet
        column_references = ::Hash.new
        if t.properties.headers == false
          # zero-based numeric keys
          for col in (1..spreadsheet.last_column)
            column_references[col] = col - 1
          end
        elsif t.properties.headers.is_a? ::Array
          # names
          for col in (1..spreadsheet.last_column)
            column_references[col] = t.properties.headers[col - 1]
          end
        else
          # read t.properties.headers from the file itself
          for col in (1..spreadsheet.last_column)
            column_references[col] = spreadsheet.cell(header_row, col)
            column_references[col] = spreadsheet.cell(header_row - 1, col) if column_references[col].blank? # lspreadsheetk up
          end
        end
        first_data_row.upto(spreadsheet.last_row) do |raw_row|
          ordered_hash = ::ActiveSupport::OrderedHash.new
          for col in (1..spreadsheet.last_column)
            next if column_references[col].blank?
            ordered_hash[column_references[col]] = spreadsheet.cell(raw_row, col).to_s.gsub(/<[^>]+>/, '').strip
          end
          yield ordered_hash if t.properties.keep_blank_rows or ordered_hash.any? { |k, v| v.present? }
        end
      ensure
        t.local_file.delete
      end

      private

      def header_row
        1 + t.properties.skip
      end

      def first_data_row
        1 + header_row
      end
    end
  end
end
