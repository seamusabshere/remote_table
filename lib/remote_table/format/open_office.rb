class RemoteTable
  class Format
    class OpenOffice < Format
      include ProcessedByRoo
      def roo_class
        ::Openoffice
      end
    end
  end
end
