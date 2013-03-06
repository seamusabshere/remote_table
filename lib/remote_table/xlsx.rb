class RemoteTable
  # Parses XLSX files using Roo's Excelx class.
  module Xlsx
    def self.extended(base)
      base.extend ProcessedByRoo
    end
    def roo_class
      Roo::Excelx
    end
  end
end
