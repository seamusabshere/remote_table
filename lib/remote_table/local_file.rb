require 'fileutils'
require 'escape'
require 'tmpdir'
class RemoteTable
  class LocalFile
    
    attr_reader :t
    
    def initialize(t)
      @t = t
      @staging_dir_path = nil # memory leak?
    end
    
    def path
      save_locally
      @path
    end
    
    private
    
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
        ::RemoteTable.executor.backtick_with_reporting %{
          curl
          --silent
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
      cmd = case t.properties.compression
      when 'zip', 'exe'
        "unzip -n #{::Escape.shell_single_word @path} -d #{::File.dirname(@path)}"
        # can't set path yet because there may be multiple files
      when 'bz2'
        "bunzip2 --stdout #{::Escape.shell_single_word @path} > #{::Escape.shell_single_word new_path}"
        @path = new_path
      when 'gz'
        "gunzip --stdout #{::Escape.shell_single_word @path} > #{::Escape.shell_single_word new_path}"
        @path = new_path
      end
      ::RemoteTable.executor.backtick_with_reporting cmd
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
    
    def staging_dir_path    
      return @staging_dir_path if @staging_dir_path.is_a?(::String)
      @staging_dir_path = ::File.join ::Dir.tmpdir, 'remote_table_gem', rand.to_s
      ::FileUtils.mkdir_p @staging_dir_path
      ::RemoteTable.cleaner.remove_at_exit @staging_dir_path
      @staging_dir_path
    end
  end
end
