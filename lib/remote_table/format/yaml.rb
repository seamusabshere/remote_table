require 'yaml'

class RemoteTable
  class Format
    class Yaml < Format
      def each(&blk)
        data = YAML.load_file t.local_file.path
        data.each &blk
      ensure
        t.local_file.cleanup
      end
    end
  end
end
