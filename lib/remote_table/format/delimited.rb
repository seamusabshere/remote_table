if RUBY_VERSION >= '1.9'
  require 'csv'
  ::RemoteTable::CSV = ::CSV
else
  begin
    require 'fastercsv'
    ::RemoteTable::CSV = ::FasterCSV
  rescue ::LoadError
    $stderr.puts "[remote_table] You probably need to manually install the fastercsv gem and/or require it in your Gemfile."
    raise $!
  end
end

class RemoteTable
  class Format
    class Delimited < Format
      include Textual
      def each(&blk)
        remove_useless_characters!
        skip_rows!
        CSV.foreach(t.local_file.path, fastercsv_options) do |row|
          if row.is_a?(CSV::Row)
            output = row.inject(::ActiveSupport::OrderedHash.new) do |memo, (key, value)|
              if key.present?
                value = '' if value.nil?
                memo[key] = utf8 value
              end
              memo
            end
            yield output if t.properties.keep_blank_rows or output.any? { |k, v| v.present? }
          else
            yield row if t.properties.keep_blank_rows or row.any? { |v| v.present? }
          end
        end
      ensure
        t.local_file.delete
      end

      private

      FASTERCSV_OPTIONS = %w{
        unconverted_fields
        col_sep
        headers
        row_sep
        return_headers
        header_converters
        quote_char
        skip_blanks
        converters
        force_quotes
      }

      def fastercsv_options
        hsh = t.options.slice *FASTERCSV_OPTIONS
        hsh.merge! 'skip_blanks' => !t.properties.keep_blank_rows
        hsh.reverse_merge! 'headers' => t.properties.headers
        hsh.reverse_merge! 'col_sep' => t.properties.delimiter
        hsh.symbolize_keys
      end
    end
  end
end
