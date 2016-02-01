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
      Engine.new(local_copy.encoded_io, csv_options.merge(headers: headers)).each do |row|

        some_value_present = false

        if not headers

          # represent the row as an array
          array = row.map do |v|
            v = RemoteTable.normalize_whitespace v
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
            next if k.nil?
            v = RemoteTable.normalize_whitespace v
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

    def csv_options
      retval = {
        skip_blanks: !keep_blank_rows,
      }
      if delimiter
        retval[:col_sep] = delimiter
      end
      if adaptive_quote_char
        retval[:quote_char] = adaptive_quote_char
      end
      retval
    end

    def adaptive_quote_char
      if quote_char
        quote_char
      elsif delimiter == "\t" or delimiter == '|'
        "\0"
      end
    end

    def headers
      return @_headers if defined?(@_headers)
      @_headers = case @headers
      when FalseClass, NilClass
        false
      when :first_row, TrueClass
        i = 0
        begin
          line = local_copy.encoded_io.gets.strip
        end while line.length == 0
        proto_headers = Engine.parse_line(line, csv_options)
        if proto_headers
          proto_headers.inject([]) do |memo, v|
            break memo if stop_after_untitled_headers and i > stop_after_untitled_headers
            header = RemoteTable.normalize_whitespace v
            memo << (header.present? ? header : "untitled_#{i+=1}")
            memo
          end
        else
          raise "No headers found in first line: #{line.inspect}"
        end
      when Array
        @headers
      else
        raise "Invalid headers: #{headers.inspect}"
      end
    end
  end
end
