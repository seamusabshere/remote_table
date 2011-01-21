require 'fileutils'
require 'escape'
require 'tmpdir'
class RemoteTable
  class LocalFile
    
    attr_reader :t
    
    def initialize(t)
      @t = t
    end
    
    def path
      download
      @path
    end
    
    private
    
    def download
      return if @path.is_a?(::String)
      @path = ::File.join staging_dir_path, 'REMOTE_TABLE_PACKAGE'
      if t.properties.uri.scheme == 'file'
        ::FileUtils.cp t.properties.uri.path, @path
      else
        # sabshere 1/20/11 FIXME: ::RemoteTable.config.curl_bin_path or smth
        ::RemoteTable.executor.backtick_with_reporting %{
          curl
          --header "Expect: "
          --location
          #{"--data #{::Escape.shell_single_word t.properties.form_data}" if t.properties.form_data.present?}
          #{::Escape.shell_single_word t.properties.uri.to_s}
          --output #{::Escape.shell_single_word @path}
          2>&1
        }
      end
      @path
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
