class RemoteTable
  class Format
    class Excel < Format
      include Rooable
      def roo_class
        ::Excel
      end
    end
  end
end
