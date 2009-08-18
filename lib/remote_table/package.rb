class RemoteTable
  class Package
    attr_accessor :url, :compression, :packing, :filename
    
    def initialize(bus)
      @url = bus[:url] or raise "need url"
      @compression = bus[:compression] || compression_from_basename
      @packing = bus[:packing] || packing_from_basename_and_compression
      @filename = bus[:filename] || filename_from_basename_and_compression_and_packing
      add_hints!(bus)
    end
    
    def add_hints!(hash)
      hash[:filename] = filename unless hash.has_key?(:filename)
    end
        
    def stage(path)
      decompress(path)
      unpack(path)
      identify(path)
      file_path(path)
    end
    
    private

    def decompress(path)
      return unless compression
      cmd, args = case compression
      when :zip, :exe
        ["unzip", "-d #{::File.dirname(path)}"]
      when :bz2
        'bunzip2'
      when :gz
        'gunzip'
      end
      move_and_process path, compression, cmd, args
    end
    
    def unpack(path)
      return unless packing
      cmd, args = case packing
      when :tar
        ['tar -xf', "-C #{::File.dirname(path)}"]
      end
      move_and_process path, packing, cmd, args
    end
    
    def move_and_process(path, extname, cmd, args)
      `mv #{path} #{path}.#{extname} && #{cmd} #{path}.#{extname} #{args}`
    end

    # ex. A: 2007-01.csv.gz  (compression not capable of storing multiple files)
    # ex. B: 2007-01.tar.gz  (packing)
    # ex. C: 2007-01.zip     (compression capable of storing multiple files)    
    # in C but not in the others, we can default to the basename of the package
    # in order to do this we'll need to mv the uncompressed file on top of the original file
    def identify(path)
      ::File.mv(path, file_path(path)) if !packing and [ nil, :bz2, :gz ].include?(compression)
    end
    
    def file_path(path)
      ::File.join(::File.dirname(path), filename)
    end

    def basename_parts
      ::File.basename(URI.parse(url).path).split('.').map(&:to_sym)
    end
    
    def compression_from_basename
      [ :zip, :exe, :bz2, :gz ].detect { |i| i == basename_parts.last }
    end

    def packing_from_basename_and_compression
      [ :tar ].detect { |i| i == ((basename_parts.last == compression) ? basename_parts[-2] : basename_parts.last) }
    end
    
    def filename_from_basename_and_compression_and_packing
      ary = basename_parts
      ary.pop if ary.last == compression
      ary.pop if ary.last == packing
      ary.join('.')
    end
  end
end
