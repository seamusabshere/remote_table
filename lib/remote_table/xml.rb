class RemoteTable
  # Parses XML files using Nokogiri's Nokogiri::XML::Document class.
  module Xml
    def self.extended(base)
      base.extend Plaintext
      base.extend ProcessedByNokogiri
    end
    
    def nokogiri_class
      ::Nokogiri::XML::Document
    end
  end
end
