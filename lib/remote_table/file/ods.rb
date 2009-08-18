class RemoteTable
  module Ods
    def self.extended(base)
      base.send :extend, RooSpreadsheet
    end
    
    def roo_klass
      Openoffice
    end
  end
end
