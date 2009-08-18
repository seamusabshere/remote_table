class RemoteTable
  module Csv
    def each_row(&block)
      skip_rows!
      FasterCSV.parse(open(path), fastercsv_options) do |row|
        if row.respond_to?(:fields) # it's a traditional fastercsv row hash
          next if row.fields.compact.blank?
          hash = HashWithIndifferentAccess.new(row.to_hash)
        else                        # it's an array, which i think happens if you're using :headers => nil or :col_sep
          next if row.compact.blank?
          index = 0
          hash = row.inject(ActiveSupport::OrderedHash.new) { |memo, element| memo[index] = element; index += 1; memo }
        end
        yield hash
      end
    ensure
      restore_rows!
    end
    
    private
    
    def fastercsv_options
      fastercsv_options = { :skip_blanks => true }              # ...and this will skip []
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
