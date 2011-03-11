if RUBY_VERSION >= '1.9'
  require 'csv'
  ::FasterCSV = ::CSV
else
  begin
    require 'fastercsv'
  rescue ::LoadError
    $stderr.puts "[remote_table gem] You probably need to manually install the fastercsv gem and/or require it in your Gemfile."
    raise $!
  end
end

class RemoteTable
  class Format
    class Delimited < Format
      include Textual
      def each(&blk)
        backup_file!
        convert_file_to_utf8!
        remove_useless_characters!
        skip_rows!
        ::FasterCSV.foreach(t.local_file.path, fastercsv_options) do |row|
          ordered_hash = ::ActiveSupport::OrderedHash.new
          filled_values = 0
          case row
          when ::FasterCSV::Row
            row.each do |header, value|
              next if header.blank?
              value = '' if value.nil?
              ordered_hash[header] = value
              filled_values += 1 if value.present?
            end
          when ::Array
            index = 0
            row.each do |value|
              value = '' if value.nil?
              ordered_hash[index] = value
              filled_values += 1 if value.present?
              index += 1
            end
          end
          yield ordered_hash if t.properties.keep_blank_rows or filled_values > 0
        end
      ensure
        restore_file!
      end

      private

      def fastercsv_options
        fastercsv_options = { :skip_blanks => !t.properties.keep_blank_rows }
        if t.properties.headers == false
          fastercsv_options.merge!(:headers => nil)
        elsif t.properties.headers.is_a?(::Array)
          fastercsv_options.merge!(:headers => t.properties.headers)
        else
          fastercsv_options.merge!(:headers => :first_row)
        end
        fastercsv_options.merge!(:col_sep => t.properties.delimiter) if t.properties.delimiter
        fastercsv_options
      end
    end
  end
end
