class RemoteTable
  module Xlsx
    def self.extended(base)
      base.send :extend, RooSpreadsheet
    end
    
    def roo_klass
      Excelx
    end
  end
end
