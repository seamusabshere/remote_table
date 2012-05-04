class RemoteTable
  class Format
    class Delimited < Format
      if ::RUBY_VERSION >= '1.9'
        require 'csv'
        Engine = ::CSV
      else
        require 'fastercsv'
        Engine = ::FasterCSV
      end

      include Textual

      def each(&blk)
        remove_useless_characters!
        fix_newlines!
        transliterate_whole_file_to_utf8!
        skip_rows!
        Engine.new(t.local_copy.encoded_io, fastercsv_options).each do |row|
          if row.is_a?(Engine::Row)
            hash = row.inject(::ActiveSupport::OrderedHash.new) do |memo, (k, v)|
              if k.present?
                memo[k] = v.to_s
              end
              memo
            end
            yield hash if t.config.keep_blank_rows or hash.any? { |k, v| v.present? }
          elsif row.is_a?(::Array)
            array = row.map { |v| v.to_s }
            yield array if t.config.keep_blank_rows or array.any? { |v| v.present? }
          end
        end
      ensure
        t.local_copy.cleanup
      end

      private

      FASTERCSV_OPTIONS = [
        :unconverted_fields,
        :col_sep,
        :headers,
        :row_sep,
        :return_headers,
        :header_converters,
        :quote_char,
        :skip_blanks,
        :converters,
        :force_quotes,
      ]

      def fastercsv_options
        hsh = t.config.user_specified_options.slice *FASTERCSV_OPTIONS
        hsh[:skip_blanks] = !t.config.keep_blank_rows
        hsh.reverse_merge! :headers => t.config.headers
        hsh.reverse_merge! :col_sep => t.config.delimiter
      end
    end
  end
end
