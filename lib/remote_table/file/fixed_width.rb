class RemoteTable
  module FixedWidth
    def each_row(&block)
      crop_rows!
      skip_rows!
      cut_columns!
      a = Slither.parse(path, schema_name)
      a[:rows].each do |hash|
        hash.reject! { |k, v| k.blank? }
        yield hash if keep_blank_rows or hash.any? { |k, v| v.present? }
      end
    ensure
      uncut_columns!
      unskip_rows!
      uncrop_rows!
    end
    
    private
    
    def cut_columns!
      return unless cut
      original = "#{path}.uncut"
      FileUtils.cp(path, original)
      `cat #{original} | cut -c #{cut} > #{path}`
    end
    
    def uncut_columns!
      return unless cut
      FileUtils.mv "#{path}.uncut", path
    end
    
    def skip_rows!
      return unless skip
      original = "#{path}.unskipped"
      FileUtils.cp(path, original)
      `cat #{original} | tail -n +#{skip + 1} > #{path}`
    end
    
    def unskip_rows!
      return unless skip
      FileUtils.mv "#{path}.unskipped", path
    end
    
    def crop_rows!
      return unless crop
      original = "#{path}.uncropped"
      FileUtils.cp(path, original)
      `cat #{original} | tail -n +#{crop.first} | head -n #{crop.last - crop.first + 1} > #{path}`
    end
    
    def uncrop_rows!
      return unless crop
      FileUtils.mv "#{path}.uncropped", path
    end
  end
end
