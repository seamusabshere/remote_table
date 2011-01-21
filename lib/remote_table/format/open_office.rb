class RemoteTable
  class Format
    class OpenOffice < Format
      include Rooable
      def roo_class
        ::Openoffice
      end
    end
  end
end
