class RemoteTable
  module Xls
    def self.extended(base)
      base.send :extend, RooSpreadsheet
    end
    
    def roo_klass
      Excel
    end
  end
end
