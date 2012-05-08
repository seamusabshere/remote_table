class RemoteTable
  # Parses [X]HTML files using Nokogiri's Nokogiri::HTML::Document class.
  module Html
    def self.extended(base)
      base.extend Plaintext
      base.extend ProcessedByNokogiri
    end
    
    def nokogiri_class
      ::Nokogiri::HTML::Document
    end
  end
end
