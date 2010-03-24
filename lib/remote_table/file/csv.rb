class RemoteTable
  module Csv
    def each_row(&block)
      backup_file!
      convert_file_to_utf8!
      skip_rows!
      FasterCSV.foreach(path, fastercsv_options) do |row|
        ordered_hash = ActiveSupport::OrderedHash.new
        filled_values = 0
        case row
        when FasterCSV::Row
          row.each do |header, value|
            next if header.blank?
            value = '' if value.nil?
            ordered_hash[header] = value
            filled_values += 1 if value.present?
          end
        when Array
          index = 0
          row.each do |value|
            value = '' if value.nil?
            ordered_hash[index] = value
            filled_values += 1 if value.present?
            index += 1
          end
        else
          raise "Unexpected #{row.inspect}"
        end
        yield ordered_hash if keep_blank_rows or filled_values.nonzero?
      end
    ensure
      restore_file!
    end
    
    private
    
    def fastercsv_options
      fastercsv_options = { :skip_blanks => !keep_blank_rows, :header_converters => lambda { |k| RemoteTable::File.convert_to_utf8 k.to_s, encoding } }
      if headers == false
        fastercsv_options.merge!(:headers => nil)
      else
        fastercsv_options.merge!(:headers => :first_row)
      end
      fastercsv_options.merge!(:col_sep => delimiter) if delimiter
      fastercsv_options
    end
  end
end
