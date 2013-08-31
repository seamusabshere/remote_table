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
      [:Openoffice, :OpenOffice]
      if ::Roo.const_defined?(:OpenOffice)
        ::Roo::OpenOffice
      elsif ::Roo.const_defined?(:Openoffice)
        ::Roo::Openoffice
      else
        raise "Couldn't find roo's OpenOffice class, maybe you need a newer version?"
      end
    end
  end
end
