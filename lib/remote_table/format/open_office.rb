class RemoteTable
  class Format
    class OpenOffice < Format
      include ProcessedByRoo
      def roo_class
        if ::RUBY_PLATFORM == 'java'
          ::Kernel.warn "[remote_table] Opening ODS files on JRuby is known to fail because of a flaw in the underlying Roo library"
        end
        ::Openoffice
      end
    end
  end
end
