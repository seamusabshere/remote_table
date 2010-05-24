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
      if parsed_url.scheme == 'file'
        parsed_url.path
      else
        path = ::File.join staging_dir_path, 'REMOTE_TABLE_PACKAGE'
        RemoteTable.backtick_with_reporting %{
          curl
          --header "Expect: "
          --location
          #{"--data #{Escape.shell_single_word form_data}" if form_data.present?}
          #{Escape.shell_single_word parsed_url.to_s}
          --output #{Escape.shell_single_word path}
          2>&1
        }
        path
      end
    end
    
    private
    
    def staging_dir_path    
      return @_staging_dir_path if @_staging_dir_path
      @_staging_dir_path = ::File.join Dir.tmpdir, rand.to_s
      FileUtils.mkdir @_staging_dir_path
      at_exit { FileUtils.rm_rf @_staging_dir_path }
      @_staging_dir_path
    end
  end
end
