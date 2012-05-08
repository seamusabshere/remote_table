class RemoteTable
  module Yaml
    def _each
      require 'yaml'
      
      data = ::YAML.load_file local_copy.path
      data.each do |row|
        yield row
      end
    ensure
      local_copy.cleanup
    end
  end
end
