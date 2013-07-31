class RemoteTable
  # Parses plaintext comma-separated (CSV), tab-separated (TSV), or really anything-delimited files using Ruby's CSV parser.
  module Delimited
    # Delimited uses Plaintext.
    def self.extended(base)
      base.extend Plaintext
    end

    if ::RUBY_VERSION >= '1.9'
      require 'csv'
      Engine = ::CSV
    else
      require 'fastercsv'
      Engine = ::FasterCSV
    end

    def preprocess!
      delete_harmful!
      convert_eol_to_unix!
      transliterate_whole_file_to_utf8!
      skip_rows!
    end

    # Yield each row using Ruby's CSV parser (FasterCSV on Ruby 1.8).
    def _each
      Engine.new(local_copy.encoded_io, csv_options).each do |row|

        some_value_present = false

        if not headers

          # represent the row as an array
          array = row.map do |v|
            v = v.to_s
            if not some_value_present and not keep_blank_rows and v.present?
              some_value_present = true
            end
            v
          end
          if some_value_present or keep_blank_rows
            yield array
          end

        else

          # represent the row as a hash
          hash = ::ActiveSupport::OrderedHash.new
          row.each do |k, v|
            v = v.to_s
            if not some_value_present and not keep_blank_rows and v.present?
              some_value_present = true
            end
            hash[k] = v
          end
          if some_value_present or keep_blank_rows
            yield hash
          end

        end
      end
    ensure
      local_copy.cleanup
    end

    # Passes user-specified options in PASSTHROUGH_CSV_SETTINGS.
    #
    # Also maps:
    # * +:headers+ directly
    # * +:keep_blank_rows+ to the CSV option +:skip_blanks+
    # * +:delimiter+ to the CSV option +:col_sep+
    #
    # @return [Hash]
    def csv_options
      {
        skip_blanks: !keep_blank_rows,
        headers:     headers,
        col_sep:     delimiter,
        quote_char:  quote_char,
      }
    end

    def headers
      return @_headers if defined?(@_headers)
      @_headers = case @headers
      when FalseClass, NilClass
        false
      when :first_row, TrueClass
        i = 0
        line = local_copy.encoded_io.gets
        Engine.parse_line(line).map do |v|
          header = v.to_s.gsub(/\s+/, ' ').strip
          header.present? ? header : "empty_#{i+=1}"
        end
      when Array
        @headers
      else
        raise "Invalid headers: #{headers.inspect}"
      end
    end
  end
end
