class RemoteTable  
  class Format
    class Unknown < StandardError; end
    
    autoload :Excel, 'remote_table/format/excel'
    autoload :Excelx, 'remote_table/format/excelx'
    autoload :Delimited, 'remote_table/format/delimited'
    autoload :OpenOffice, 'remote_table/format/open_office'
    autoload :FixedWidth, 'remote_table/format/fixed_width'
    autoload :HTML, 'remote_table/format/html'
    
    autoload :Textual, 'remote_table/format/mixins/textual'
    autoload :Rooable, 'remote_table/format/mixins/rooable'
    
    attr_reader :t

    def initialize(t)
      @t = t
    end
    
    include ::Enumerable
    def each
      raise "must be defined by format"
    end
    
    def backup_file!
      ::FileUtils.cp t.local_file.path, "#{t.local_file.path}.backup"
    end
    
    def restore_file!
      return unless ::File.readable? "#{t.local_file.path}.backup"
      ::FileUtils.mv "#{t.local_file.path}.backup", t.local_file.path
    end
  end
end
