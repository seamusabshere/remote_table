require 'fileutils'
require 'escape'
require 'tmpdir'
class RemoteTable
  class LocalFile #:nodoc:all
    
    attr_reader :t
    
    def initialize(t)
      @t = t
    end
    
    def path
      save_locally
      @path
    end
    
    def encoded_io
      @encoded_io ||= if ::RUBY_VERSION >= '1.9'
        ::File.open path, 'rb', :internal_encoding => t.properties.internal_encoding, :external_encoding => t.properties.external_encoding
      else
        ::File.open path, 'rb'
      end
    end
    
    def delete
      if @encoded_io.respond_to?(:closed?) and !@encoded_io.closed?
        @encoded_io.close
      end
      ::FileUtils.rm_rf staging_dir_path
      @encoded_io = nil
      @path = nil
      @staging_dir_path = nil
    end
    
    private
    
    def staging_dir_path #:nodoc:
      return @staging_dir_path if @staging_dir_path.is_a?(::String)
      srand # in case this was forked by resque
      @staging_dir_path = ::File.join ::Dir.tmpdir, 'remote_table_gem', rand.to_s
      ::FileUtils.mkdir_p @staging_dir_path
      @staging_dir_path
    end
    
    def save_locally
      return if @path.is_a?(::String)
      @path = ::File.join(staging_dir_path, ::File.basename(t.properties.uri.path))
      download
      decompress
      unpack
      pick
      @path
    end
    
    def download
      if t.properties.uri.scheme == 'file'
        ::FileUtils.cp t.properties.uri.path, @path
      else
        # sabshere 1/20/11 FIXME: ::RemoteTable.config.curl_bin_path or smth
        # sabshere 7/20/11 make web requests move more slowly so you don't get accused of DOS
        sleep t.properties.delay_between_requests if t.properties.delay_between_requests
        $stderr.puts "[remote_table] Downloading #{t.properties.uri.to_s}"
        ::RemoteTable.executor.backtick_with_reporting %{
          curl
          --silent
          --show-error
          --location
          --header "Expect: "
          #{"--data #{::Escape.shell_single_word t.properties.form_data}" if t.properties.form_data.present?}
          --output #{::Escape.shell_single_word @path}
          #{::Escape.shell_single_word t.properties.uri.to_s}
          2>&1
        }
      end
    end
    
    def decompress
      return unless t.properties.compression
      new_path = @path.chomp ".#{t.properties.compression}"
      raise_on_error = true
      cmd = case t.properties.compression
      when 'zip', 'exe'
        # can't set path yet because there may be multiple files
        raise_on_error = false
        "unzip -qq -n #{::Escape.shell_single_word @path} -d #{::File.dirname(@path)}"
      when 'bz2'
        @path = new_path
        "bunzip2 --stdout #{::Escape.shell_single_word @path} > #{::Escape.shell_single_word new_path}"
      when 'gz'
        @path = new_path
        "gunzip --stdout #{::Escape.shell_single_word @path} > #{::Escape.shell_single_word new_path}"
      end
      ::RemoteTable.executor.backtick_with_reporting cmd, raise_on_error
    end
    
    def unpack
      return unless t.properties.packing
      cmd = case t.properties.packing
      when 'tar'
        "tar -xf #{::Escape.shell_single_word @path} -C #{::File.dirname(@path)}"
      end
      ::RemoteTable.executor.backtick_with_reporting cmd
    end
    
    # ex. A: 2007-01.csv.gz  (compression not capable of storing multiple files)
    # ex. B: 2007-01.tar.gz  (packing)
    # ex. C: 2007-01.zip     (compression capable of storing multiple files)
    def pick
      if t.properties.filename.present?
        @path = ::File.join ::File.dirname(@path), t.properties.filename
      elsif t.properties.glob.present?
        @path = ::Dir[::File.dirname(@path)+t.properties.glob].first
      end
    end
  end
end
