require 'fileutils'

class RemoteTable
  class LocalFile #:nodoc:all
    
    attr_reader :t
    
    def initialize(t)
      @t = t
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
      tmp_path = Utils.download t.config.uri, t.config.form_data
      if compression = t.config.compression
        tmp_path = Utils.decompress tmp_path, compression
      end
      if packing = t.config.packing
        tmp_path = Utils.unpack tmp_path, packing
      end
      @path = Utils.pick tmp_path, :filename => t.config.filename, :glob => t.config.glob
      @generated = true
    end
  end
end
