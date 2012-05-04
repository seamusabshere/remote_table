require 'yaml'

class RemoteTable
  class Format
    class Yaml < Format
      def each(&blk)
        data = YAML.load_file t.local_copy.path
        data.each &blk
      ensure
        t.local_copy.cleanup
      end
    end
  end
end
