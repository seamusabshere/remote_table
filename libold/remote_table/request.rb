class RemoteTable
  class Request
    attr_accessor :parsed_url, :post_data, :username, :password
    attr_accessor :form_data
    
    # TODO: support HTTP basic auth
    def initialize(bus)
      raise(ArgumentError, "RemoteTable needs :url option") unless bus[:url].present?
      @parsed_url = URI.parse bus[:url]
      if @parsed_url.host == 'spreadsheets.google.com'
        if bus[:format].blank? or bus[:format].to_s == 'csv'
          @parsed_url.query = 'output=csv&' + @parsed_url.query.sub(/\&?output=.*?(\&|\z)/, '\1')
        end
      end
      @form_data = bus[:form_data]
    end
    
    def download
      path = ::File.join staging_dir_path, 'REMOTE_TABLE_PACKAGE'
      if parsed_url.scheme == 'file'
        ::FileUtils.cp parsed_url.path, path
      else
        RemoteTable.backtick_with_reporting %{
          curl
          --header "Expect: "
          --location
          #{"--data #{Escape.shell_single_word form_data}" if form_data.present?}
          #{Escape.shell_single_word parsed_url.to_s}
          --output #{Escape.shell_single_word path}
          2>&1
        }
      end
      path
    end
    
    def staging_dir_path    
      return @_staging_dir_path if @_staging_dir_path
      @_staging_dir_path = ::File.join Dir.tmpdir, 'remote_table_gem', rand.to_s
      FileUtils.mkdir_p @_staging_dir_path
      RemoteTable.remove_at_exit @_staging_dir_path
      @_staging_dir_path
    end
  end
end
