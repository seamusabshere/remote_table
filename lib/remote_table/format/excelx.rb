class RemoteTable
  class Format
    class Excelx < Format
      include ProcessedByRoo
      def roo_class
        ::Excelx
      end
    end
  end
end
