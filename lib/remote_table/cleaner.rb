require 'singleton'
require 'fileutils'
class RemoteTable
  class Cleaner
    include ::Singleton
    def paths_for_removal
      @paths_for_removal ||= []
    end
    def cleanup
      paths_for_removal.each do |path|
        ::FileUtils.rm_rf path
        paths_for_removal.delete path
      end
    end
    def remove_at_exit(path)
      paths_for_removal << path
    end
  end
end
