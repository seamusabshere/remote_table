require 'fileutils'
require 'unix_utils'

class RemoteTable
  class LocalFile #:nodoc:all
    class << self
      def decompress(input, compression)
        case compression
        when :zip, :exe
          ::UnixUtils.unzip input
        when :bz2
          ::UnixUtils.bunzip2 input
        when :gz
          ::UnixUtils.gunzip input
        else
          raise ::ArgumentError, "Unrecognized compression #{compression}"
        end
      end
      
      def unpack(input, packing)
        case packing
        when :tar
          ::UnixUtils.untar input
        else
          raise ::ArgumentError, "Unrecognized packing #{packing}"
        end
      end
      
      def pick(input, options = {})
        options = options.symbolize_keys
        if (options[:filename] or options[:glob]) and not ::File.directory?(input)
          raise ::RuntimeError, "Expecting #{input} to be a directory"
        end
        if filename = options[:filename]
          src = ::File.join input, filename
          raise(::RuntimeError, "Expecting #{src} to be a file") unless ::File.file?(src)
          output = ::UnixUtils.tmp_path src
          ::FileUtils.mv src, output
          ::FileUtils.rm_rf input if ::File.dirname(input).start_with?(::Dir.tmpdir)
        elsif glob = options[:glob]
          src = ::Dir[input+glob].first
          raise(::RuntimeError, "Expecting #{glob} to find a file in #{input}") unless src and ::File.file?(src)
          output = ::UnixUtils.tmp_path src
          ::FileUtils.mv src, output
          ::FileUtils.rm_rf input if ::File.dirname(input).start_with?(::Dir.tmpdir)
        else
          output = ::UnixUtils.tmp_path input
          ::FileUtils.mv input, output
        end
        output
      end
    end
    
    attr_reader :t
    
    def initialize(t)
      @t = t
    end

    def in_place(*args)
      bin = args.shift
      tmp_path = ::UnixUtils.send(*([bin,path]+args))
      ::FileUtils.mv tmp_path, path
    end
    
    def path
      generate unless generated?
      @path
    end
    
    def encoded_io
      @encoded_io ||= if ::RUBY_VERSION >= '1.9'
        ::File.open path, 'rb', :internal_encoding => t.config.internal_encoding, :external_encoding => t.config.external_encoding
      else
        ::File.open path, 'rb'
      end
    end
    
    def cleanup
      if @encoded_io.respond_to?(:closed?) and !@encoded_io.closed?
        @encoded_io.close
      end
      @encoded_io = nil
      if @path and ::File.exist?(@path)
        ::FileUtils.rm_f @path
      end
      @path = nil
      @generated = nil
    end
    
    private
    
    def generated?
      @generated == true
    end
        
    def generate
      tmp_path = ::UnixUtils.curl t.config.uri.to_s, t.config.form_data
      if compression = t.config.compression
        tmp_path = LocalFile.decompress tmp_path, compression
      end
      if packing = t.config.packing
        tmp_path = LocalFile.unpack tmp_path, packing
      end
      @path = LocalFile.pick tmp_path, :filename => t.config.filename, :glob => t.config.glob
      @generated = true
    end
  end
end
