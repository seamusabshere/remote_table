class RemoteTable
  class Format
    class Excel < Format
      include ProcessedByRoo
      def roo_class
        ::Excel
      end
    end
  end
end
