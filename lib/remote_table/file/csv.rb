class RemoteTable
  module Csv
    def each_row(&block)
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
      restore_rows!
    end
    
    private
    
    def fastercsv_options
      fastercsv_options = { :skip_blanks => !keep_blank_rows, :header_converters => lambda { |k| k.to_s.toutf8 } }
      if headers == false
        fastercsv_options.merge!(:headers => nil)
      else
        fastercsv_options.merge!(:headers => :first_row)
      end
      fastercsv_options.merge!(:col_sep => delimiter) if delimiter
      fastercsv_options
    end
    
    def skip_rows!
      return unless skip
      original = "#{path}.original"
      FileUtils.cp(path, original)
      `cat #{original} | tail -n +#{skip + 1} > #{path}`
    end
    
    def restore_rows!
      return unless skip
      FileUtils.mv "#{path}.original", path
    end
  end
end
