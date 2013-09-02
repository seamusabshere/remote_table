class RemoteTable
  # Mixed in to process XLS, XLSX, and ODS with the Roo library.
  module ProcessedByRoo
    TAG = /<[^>]+>/
    BLANK = ''

    # Yield each row using Roo.
    def _each
      require 'roo'

      spreadsheet = roo_class.new local_copy.path, nil, :ignore
      if sheet
        spreadsheet.default_sheet = sheet
      end

      first_row = if crop
        crop.first + 1
      else
        skip + 1
      end

      last_row = if crop
        crop.last
      else
        spreadsheet.last_row
      end

      if not headers

        # create an array to represent this row
        (first_row..last_row).each do |y|
          some_value_present = false
          output = (1..spreadsheet.last_column).map do |x|
            memo = spreadsheet.cell(y, x).to_s.dup
            memo = assume_utf8 memo
            memo.gsub! TAG, BLANK
            memo.strip!
            if not some_value_present and not keep_blank_rows and memo.present?
              some_value_present = true
            end
            memo
          end
          if keep_blank_rows or some_value_present
            yield output
          end
        end

      else

        # create a hash to represent this row
        current_headers = ::ActiveSupport::OrderedHash.new
        if headers == :first_row
          (1..spreadsheet.last_column).each do |x|
            v = spreadsheet.cell(first_row, x)
            if v.blank?
              # then look up one
              v = spreadsheet.cell(first_row - 1, x)
            end
            if v.present?
              v = assume_utf8 v
              # 'foobar' is found at column 6
              current_headers[v] = x
            end
          end
          # "advance the cursor"
          first_row += 1
        else
          headers.each_with_index do |k, i|
            current_headers[k] = i + 1
          end
        end
        (first_row..last_row).each do |y|
          some_value_present = false
          output = ::ActiveSupport::OrderedHash.new
          current_headers.each do |k, x|
            memo = spreadsheet.cell(y, x).to_s.dup
            memo = assume_utf8 memo
            memo.gsub! TAG, BLANK
            memo.strip!
            if not some_value_present and not keep_blank_rows and memo.present?
              some_value_present = true
            end
            output[k] = memo
          end
          if keep_blank_rows or some_value_present
            yield output
          end
        end

      end
    ensure
      local_copy.cleanup
    end
  end
end
