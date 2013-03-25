class RemoteTable
  # Parses ODS files using Roo's Openoffice class.
  #
  # Know to have issues on JRuby.
  module Ods
    def self.extended(base)
      base.extend ProcessedByRoo
    end

    def roo_class
      if ::RUBY_PLATFORM == 'java'
        ::Kernel.warn "[remote_table] Opening ODS files on JRuby is known to fail because of a flaw in the underlying Roo library"
      end
      Roo.const_defined?(:Openoffice) ? Roo::Openoffice : ::Openoffice
    end
  end
end
