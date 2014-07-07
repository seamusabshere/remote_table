class RemoteTable
  module Json
    def _each
      require 'json'
     
      data.each do |row|
        yield row
      end
    ensure
      local_copy.cleanup
    end

    private

    def json_string
      local_copy.encoded_io.read
    end

    def parsed_json
      ::JSON.parse(json_string)
    end

    def data
      root_node.nil? ? parsed_json : parsed_json[root_node]
    end
  end
end
