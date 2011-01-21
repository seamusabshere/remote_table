class RemoteTable
  module RooSpreadsheet
    def each_row(&block)
      oo = roo_klass.new(path, nil, :ignore)
      oo.default_sheet = sheet.is_a?(Numeric) ? oo.sheets[sheet] : sheet
      column_references = Hash.new
      if headers == false
        # zero-based numeric keys
        for col in (1..oo.last_column)
          column_references[col] = col - 1
        end
      elsif headers.is_a? Array
        # names
        for col in (1..oo.last_column)
          column_references[col] = headers[col - 1]
        end
      else
        # read headers from the file itself
        for col in (1..oo.last_column)
          column_references[col] = oo.cell(header_row, col)
          column_references[col] = oo.cell(header_row - 1, col) if column_references[col].blank? # look up
        end
      end
      first_data_row.upto(oo.last_row) do |raw_row|
        ordered_hash = ActiveSupport::OrderedHash.new
        for col in (1..oo.last_column)
          next if column_references[col].blank?
          ordered_hash[column_references[col]] = oo.cell(raw_row, col).to_s.gsub(/<[^>]+>/, '').strip
        end
        yield ordered_hash if keep_blank_rows or ordered_hash.any? { |k, v| v.present? }
      end
    end

    private

    def header_row
      1 + skip.to_i
    end

    def first_data_row
      1 + header_row
    end
  end
end
