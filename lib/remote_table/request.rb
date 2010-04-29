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
        parsed_url.path
      else
        RemoteTable.backtick_with_reporting %{
          curl
          --header "Expect: "
          --location
          #{"--data \"#{form_data}\"" if form_data.present?}
          "#{parsed_url}"
          --output "#{path}"
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
