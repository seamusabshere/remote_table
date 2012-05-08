require 'fileutils'
require 'unix_utils'

class RemoteTable
  # @private
  class LocalCopy
    class << self
      def decompress(input, compression)
        output = case compression
        when :zip, :exe
          ::UnixUtils.unzip input
        when :bz2
          ::UnixUtils.bunzip2 input
        when :gz
          ::UnixUtils.gunzip input
        else
          raise ::ArgumentError, "Unrecognized compression #{compression}"
        end
        ::FileUtils.rm_f input
        output
      end
      
      def unpack(input, packing)
        output = case packing
        when :tar
          ::UnixUtils.untar input
        else
          raise ::ArgumentError, "Unrecognized packing #{packing}"
        end
        ::FileUtils.rm_f input
        output
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
      @encoded_io_mutex = ::Mutex.new
      @generate_mutex = ::Mutex.new
    end

    def in_place(*args)
      bin = args.shift
      tmp_path = ::UnixUtils.send(*([bin,path]+args))
      ::FileUtils.mv tmp_path, path
    end
    
    def path
      generate unless @generated
      @path
    end
    
    def encoded_io
      @encoded_io || @encoded_io_mutex.synchronize do
        @encoded_io ||= if ::RUBY_VERSION >= '1.9'
          ::File.open path, 'rb', :internal_encoding => t.internal_encoding, :external_encoding => RemoteTable::EXTERNAL_ENCODING
        else
          ::File.open path, 'rb'
        end
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
    
    def generate
      return if @generated
      @generate_mutex.synchronize do
        return if @generated
        @generated = true
        # sabshere 7/20/11 make web requests move more slowly so you don't get accused of DOS
        if ::ENV.has_key?('REMOTE_TABLE_DELAY_BETWEEN_REQUESTS')
          ::Kernel.sleep ::ENV['REMOTE_TABLE_DELAY_BETWEEN_REQUESTS'].to_i
        end
        tmp_path = ::UnixUtils.curl t.url, t.form_data
        if compression = t.compression
          tmp_path = LocalCopy.decompress tmp_path, compression
        end
        if packing = t.packing
          tmp_path = LocalCopy.unpack tmp_path, packing
        end
        @path = LocalCopy.pick tmp_path, :filename => t.filename, :glob => t.glob
      end
    end
  end
end
