class RemoteTable
  class Request
    attr_accessor :url, :post_data, :username, :password
    
    # TODO: support post_data
    # TODO: support HTTP basic auth
    def initialize(bus)
      @url = bus[:url] or raise "need url"
    end
    
    def download
      path = ::File.join(staging_dir_path, 'REMOTE_TABLE_PACKAGE')
      `curl --silent \"#{url_with_google_docs_handling}\" > #{path}`
      path
    end
    
    private
    
    def staging_dir_path
      path = tempfile_path_from_url
      FileUtils.rm_f(path)
      FileUtils.mkdir(path)
      at_exit { FileUtils.rm_rf(path) }
      path
    end
    
    def tempfile_path_from_url
      Tempfile.open(url.gsub(/[^a-z0-9]+/i, '_')[0,100]).path
    end
    
    def url_with_google_docs_handling
      url = self.url
      if url.include?('spreadsheets.google.com')
        url = url.gsub(/\&output=.*(\&|\z)/, '')
        url << "&output=csv"
      end
      url
    end
  end
end
