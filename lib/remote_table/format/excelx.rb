class RemoteTable
  class Format
    class Excelx < Format
      include Rooable
      def roo_class
        ::Excelx
      end
    end
  end
end
