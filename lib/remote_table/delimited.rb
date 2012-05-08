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

    PASSTHROUGH_CSV_SETTINGS = [
      :unconverted_fields,
      :col_sep,
      :row_sep,
      :return_headers,
      :header_converters,
      :quote_char,
      :converters,
      :force_quotes,
    ]

    # Yield each row using Ruby's CSV parser (FasterCSV on Ruby 1.8).
    def _each
      delete_harmful!
      convert_eol_to_unix!
      transliterate_whole_file_to_utf8!
      skip_rows!

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
            next unless k.present?
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
      memo = other_options.slice(*PASSTHROUGH_CSV_SETTINGS)
      memo[:skip_blanks] = !keep_blank_rows
      memo[:headers] ||= headers
      memo[:col_sep] ||= delimiter
      memo
    end
  end
end
