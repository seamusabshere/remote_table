class RemoteTable
  # Parses XLSX files using Roo's Excelx class.
  module Xlsx
    def self.extended(base)
      base.extend ProcessedByRoo
    end
    def roo_class
      ::Excelx
    end
  end
end
