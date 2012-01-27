require 'uri'
class RemoteTable
  # Represents the config of a RemoteTable, whether they are explicitly set by the user or inferred automatically.
  class Config
    attr_reader :t
    attr_reader :user_specified_options
    
    def initialize(t, user_specified_options)
      @t = t
      @user_specified_options = user_specified_options
    end
            
    # The parsed URI of the file to get.
    def uri
      return @uri if @uri.is_a?(::URI)
      @uri = ::URI.parse t.url
      if @uri.host == 'spreadsheets.google.com' or @uri.host == 'docs.google.com'
        @uri.query = 'output=csv&' + @uri.query.sub(/\&?output=.*?(\&|\z)/, '\1')
      end
      @uri
    end
    
    # Whether to stream the rows without caching them. Saves memory, but you have to re-download the file every time you...
    # * call []
    # * call each
    # Defaults to false.
    def streaming
      user_specified_options[:streaming] || false
    end

    # Defaults to true.
    def warn_on_multiple_downloads
      user_specified_options[:warn_on_multiple_downloads] != false
    end
    
    # The headers specified by the user
    #
    # Default: :first_row
    def headers
      user_specified_options[:headers].nil? ? :first_row : user_specified_options[:headers]
    end
    
    def use_first_row_as_header?
      headers == :first_row
    end
    
    def output_class
      headers == false ? ::Array : ::ActiveSupport::OrderedHash
    end
    
    # The sheet specified by the user as a number or a string
    #
    # Default: 0
    def sheet
      user_specified_options[:sheet] || 0
    end
    
    # Whether to keep blank rows
    #
    # Default: false
    def keep_blank_rows
      user_specified_options[:keep_blank_rows] || false
    end
    
    # Form data to send in with the download request
    def form_data
      user_specified_options[:form_data]
    end
    
    # How many rows to skip
    #
    # Default: 0
    def skip
      user_specified_options[:skip] || 0
    end
    
    def internal_encoding
      (user_specified_options[:encoding] || 'UTF-8').upcase
    end
    
    def external_encoding
      'UTF-8'
    end
    
    def external_encoding_iconv
      'UTF-8//TRANSLIT'
    end
    
    # The delimiter
    #
    # Default: ","
    def delimiter
      user_specified_options[:delimiter] || ','
    end
    
    # The XPath used to find rows
    def row_xpath
      user_specified_options[:row_xpath]
    end
    
    # The XPath used to find columns
    def column_xpath
      user_specified_options[:column_xpath]
    end

    # The CSS selector used to find rows
    def row_css
      user_specified_options[:row_css]
    end
    
    # The CSS selector used to find columns
    def column_css
      user_specified_options[:column_css]
    end
    
    # The compression type.
    #
    # Default: guessed from URI.
    #
    # Can be specified as: :gz, :zip, :bz2, :exe (treated as :zip)
    def compression
      if user_specified_options.has_key?(:compression)
        return user_specified_options[:compression]
      end
      case ::File.extname(uri.path).downcase
      when /gz/, /gunzip/
        :gz
      when /zip/
        :zip
      when /bz2/, /bunzip2/
        :bz2
      when /exe/
        :exe
      end
    end
    
    # The packing type.
    #
    # Default: guessed from URI.
    #
    # Can be specified as: :tar
    def packing
      if user_specified_options.has_key?(:packing)
        return user_specified_options[:packing]
      end
      if uri.path =~ %r{\.tar(?:\.|$)}i
        :tar
      end
    end
    
    # The glob used to pick a file out of an archive.
    #
    # Example:
    #     RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :glob => '/*.csv'
    def glob
      user_specified_options[:glob]
    end
    
    # The filename, which can be used to pick a file out of an archive.
    #
    # Example:
    #     RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :filename => '2008_FE_guide_ALL_rel_dates_-no sales-for DOE-5-1-08.csv'
    def filename
      user_specified_options[:filename]
    end
    
    # Cut columns up to this character
    def cut
      user_specified_options[:cut]
    end
    
    # Crop rows after this line
    def crop
      user_specified_options[:crop]
    end
    
    # The fixed-width schema, given as an array
    #
    # Example:
    #     RemoteTable.new('http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
    #                      :format => :fixed_width,
    #                      :skip => 1,
    #                      :schema => [[ 'header4', 10, { :type => :string }  ],
    #                                  [  'spacer',  1 ],
    #                                  [  'header5', 10, { :type => :string } ],
    #                                  [  'spacer',  12 ],
    #                                  [  'header6', 10, { :type => :string } ]])
    def schema
      user_specified_options[:schema]
    end
    
    # The name of the fixed-width schema according to FixedWidth
    def schema_name
      user_specified_options[:schema_name]
    end
    
    # A proc to call to decide whether to return a row.
    def select
      user_specified_options[:select]
    end
    
    # A proc to call to decide whether to return a row.
    def reject
      user_specified_options[:reject]
    end
    
    # A hash of options to create a new Errata instance (see the Errata gem at http://github.com/seamusabshere/errata) to be used on every row.
    def errata
      return unless user_specified_options.has_key? :errata
      @errata ||= if user_specified_options[:errata].is_a? ::Hash
        ::Errata.new user_specified_options[:errata]
      else
        user_specified_options[:errata]
      end
    end
    
    # Get the format in the form of RemoteTable::Format::Excel, etc.
    #
    # Note: treats all spreadsheets.google.com URLs as Format::Delimited (i.e., CSV)
    #
    # Default: guessed from file extension (which is usually the same as the URI, but sometimes not if you pick out a specific file from an archive)
    #
    # Can be specified as: :xlsx, :xls, :delimited (aka :csv and :tsv), :ods, :fixed_width, :html
    def format
      return Format::Delimited if uri.host == 'spreadsheets.google.com' or @uri.host == 'docs.google.com'
      clue = if user_specified_options.has_key?(:format)
        user_specified_options[:format]
      else
        t.local_file.path
      end
      case clue.to_s.downcase
      when /xlsx/, /excelx/
        Format::Excelx
      when /xls/, /excel/
        Format::Excel
      when /csv/, /tsv/, /delimited/
        Format::Delimited
      when /ods/, /open_?office/
        Format::OpenOffice
      when /fixed_?width/
        Format::FixedWidth
      when /htm/
        Format::HTML
      when /xml/
        Format::XML
      else
        Format::Delimited
      end
    end
  end
end
