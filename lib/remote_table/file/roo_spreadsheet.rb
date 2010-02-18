class RemoteTable
  module RooSpreadsheet
    def each_row(&block)
      headers = Hash.new
      oo = roo_klass.new(path, nil, :ignore)
      oo.default_sheet = sheet.is_a?(Numeric) ? oo.sheets[sheet] : sheet
      for col in (1..oo.last_column)
        headers[col] = oo.cell(header_row, col)
        headers[col] = oo.cell(header_row - 1, col) if headers[col].blank? # look up
      end
      first_data_row.upto(oo.last_row) do |raw_row|
        ordered_hash = ActiveSupport::OrderedHash.new
        for col in (1..oo.last_column)
          next if headers[col].blank?
          ordered_hash[headers[col]] = oo.cell(raw_row, col).to_s.gsub(/<[^>]+>/, '').strip
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
