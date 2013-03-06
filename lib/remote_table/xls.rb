class RemoteTable
  # Parses XLS files using Roo's Excel class.
  module Xls
    def self.extended(base)
      base.extend ProcessedByRoo
    end
    def roo_class
      Roo::Excel
    end
  end
end
