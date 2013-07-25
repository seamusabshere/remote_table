if ::RUBY_VERSION < '1.9' and $KCODE != 'UTF8'
  ::Kernel.warn "[remote_table] Ruby 1.8 detected, setting $KCODE to UTF8 so that ActiveSupport::Multibyte works properly."
  $KCODE = 'UTF8'
end

require 'thread'

require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR >= 3
  require 'active_support/core_ext'
  require 'active_support/inflector/transliterate'
end
require 'hash_digest'

require 'remote_table/local_copy'

require 'remote_table/plaintext'
require 'remote_table/processed_by_roo'
require 'remote_table/processed_by_nokogiri'
require 'remote_table/xls'
require 'remote_table/xlsx'
require 'remote_table/delimited'
require 'remote_table/ods'
require 'remote_table/fixed_width'
require 'remote_table/html'
require 'remote_table/xml'
require 'remote_table/yaml'

class Hash
  # Added by remote_table to store a hash (think checksum) of the data with which a particular Hash is initialized.
  # @return [String]
  attr_accessor :row_hash
end

class Array
  # Added by remote_table to store a hash (think checksum) of the data with which a particular Array is initialized.
  # @return [String]
  attr_accessor :row_hash
end

# Open Google Docs spreadsheets, local or remote XLSX, XLS, ODS, CSV (comma separated), TSV (tab separated), other delimited, fixed-width files.
class RemoteTable
  class << self
    # Guess compression based on URL. Used internally.
    # @return [Symbol,nil]
    def guess_compression(url)
      extname = ::File.extname(::URI.parse(url).path).downcase
      case extname
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

    # Guess packing from URL. Used internally.
    # @return [Symbol,nil]
    def guess_packing(url)
      basename = ::File.basename(::URI.parse(url).path).downcase
      if basename.include?('.tar') or basename.include?('.tgz')
        :tar
      end
    end

    # Guess file format from the basename. Since a file might be decompressed and/or pulled out of an archive with a glob, this usually can't be called until a file is downloaded.
    # @return [Symbol,nil]
    def guess_format(basename)
      case basename.to_s.downcase
      when /ods/, /open_?office/
        :ods
      when /xlsx/, /excelx/
        :xlsx
      when /xls/, /excel/
        :xls
      when /csv/, /tsv/, /delimited/
        # note that there is no RemoteTable::Csv class - it's normalized to :delimited
        :delimited
      when /fixed_?width/
        :fixed_width
      when /htm/
        :html
      when /xml/
        :xml
      when /yaml/, /yml/
        :yaml
      end
    end

    # Given a Google Docs spreadsheet URL, make sure it uses CSV output.
    # @return [String]
    def google_spreadsheet_csv_url(url)
      uri = ::URI.parse url
      params = uri.query.split('&')
      params.delete_if { |param| param.start_with?('output=') }
      params << 'output=csv'
      uri.query = params.join('&')
      uri.to_s
    end
  end

  EXTERNAL_ENCODING = 'UTF-8'
  EXTERNAL_ENCODING_ICONV = 'UTF-8//TRANSLIT'
  GOOGLE_DOCS_SPREADSHEET = [
    /docs.google.com/i,
    /spreadsheets.google.com/i
  ]
  VALID = {
    :compression => [:gz, :zip, :bz2, :exe],
    :packing => [:tar],
    :format => [:xlsx, :xls, :delimited, :ods, :fixed_width, :html, :xml, :yaml, :csv],
  }
  DEFAULT = {
    :streaming => false,
    :warn_on_multiple_downloads => true,
    :headers => :first_row,
    :keep_blank_rows => false,
    :skip => 0,
    :encoding => 'UTF-8',
    :delimiter => ','
  }
  OLD_SETTING_NAMES = {
    :pre_select => [:select],
    :pre_reject => [:reject],
  }

  include ::Enumerable
  
  # The URL of the local or remote file.
  #
  # @example Local
  #   file:///Users/myuser/Desktop/holidays.csv
  #
  # @example Local using an absolute path
  #   /Users/myuser/Desktop/holidays.csv
  #
  # @example Remote
  #   http://data.brighterplanet.com/countries.csv
  #
  # @return [String]
  attr_reader :url

  # @private
  # A cache of rows, created unless +:streaming+ is enabled.
  # @return [Array<Hash,Array>]
  attr_reader :cache

  # @private
  # How many times this file has been downloaded. RemoteTable will emit a warning if you download it more than once.
  # @return [Integer]
  attr_reader :download_count

  # @private
  # Used internally to access to a downloaded copy of the file.
  # @return [RemoteTable::LocalCopy]
  attr_reader :local_copy

  # Whether to stream the rows without caching them. Saves memory, but you have to re-download the file every time you enumerate its rows. Defaults to false.
  # @return [true,false]
  attr_reader :streaming

  # Whether to warn the user on multiple downloads. Defaults to true.
  # @return [true,false]
  attr_reader :warn_on_multiple_downloads
  
  # Headers specified by the user: +:first_row+ (the default), +false+, or a list of headers.
  # @return [:first_row,false,Array<String>]
  attr_reader :headers
    
  # The sheet specified by the user as a number or a string.
  # @return[String,Integer]
  attr_reader :sheet
  
  # Whether to keep blank rows. Default is false.
  # @return [true,false]
  attr_reader :keep_blank_rows
  
  # Form data to POST in the download request. It should probably be in +application/x-www-form-urlencoded+.
  # @return [String]
  attr_reader :form_data
  
  # How many rows to skip at the beginning of the file or table. Default is 0.
  # @return [Integer]
  attr_reader :skip

  # The original encoding of the source file. Default is UTF-8.
  # @return [String]
  attr_reader :encoding
  
  # The delimiter, a.k.a. column separator. Passed to Ruby CSV as +:col_sep+. Default is :delimited.
  # @return [String]
  attr_reader :delimiter
  
  # The XPath used to find rows in HTML or XML.
  # @return [String]
  attr_reader :row_xpath
  
  # The XPath used to find columns in HTML or XML.
  # @return [String]
  attr_reader :column_xpath

  # The CSS selector used to find rows in HTML or XML.
  # @return [String]
  attr_reader :row_css
  
  # The CSS selector used to find columns in HTML or XML.
  # @return [String]
  attr_reader :column_css
  
  # The format of the source file. Can be +:xlsx+, +:xls+, +:delimited+, +:ods+, +:fixed_width+, +:html+, +:xml+, +:yaml+.
  # @return [Symbol]
  attr_reader :format

  # The compression type. Guessed from URL if not provided. +:gz+, +:zip+, +:bz2+, and +:exe+ (treated as +:zip+) are supported.
  # @return [Symbol]
  attr_reader :compression

  # The packing type. Guessed from URL if not provided. Only +:tar+ is supported.
  # @return [Symbol]
  attr_reader :packing
  
  # The glob used to pick a file out of an archive.
  #
  # @return [String]
  #
  # @example Pick out the only CSV in a ZIP file
  #   RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :glob => '/*.csv'
  attr_reader :glob
  
  # The filename, which can be used to pick a file out of an archive.
  #
  # @return [String]
  #
  # @example Specify the filename to get out of a ZIP file
  #   RemoteTable.new 'http://www.fueleconomy.gov/FEG/epadata/08data.zip', :filename => '2008_FE_guide_ALL_rel_dates_-no sales-for DOE-5-1-08.csv'
  attr_reader :filename

  # Pick specific columns out of a plaintext file using an argument to the UNIX [+cut+ utility](http://en.wikipedia.org/wiki/Cut_%28Unix%29).
  #
  # @return [String]
  #
  # @example Pick ALMOST out of ABCDEFGHIJKLMNOPQRSTUVWXYZ
  #   # $ echo ABCDEFGHIJKLMNOPQRSTUVWXYZ | cut -c '1,12,13,15,19,20'
  #   # ALMOST
  #   RemoteTable.new 'file:///atoz.txt', :cut => '1,12,13,15,19,20'
  attr_reader :cut
  
  # Use a range of rows in a plaintext file.
  #
  # @return [Range]
  #
  # @example Only take rows 21 through 37
  #   RemoteTable.new("http://www.eia.gov/emeu/cbecs/cbecs2003/detailed_tables_2003/2003set10/2003excel/C17.xls",
  #                   :headers => false,
  #                   :select => proc { |row| CbecsEnergyIntensity::NAICS_CODE_SYNTHESIZER.call(row) },
  #                   :crop => (21..37))
  attr_reader :crop
  
  # The fixed-width schema, given as a multi-dimensional array.
  #
  # @return [Array<Array{String,Integer,Hash}>]
  #
  # @example From the tests
  #   RemoteTable.new('http://cloud.github.com/downloads/seamusabshere/remote_table/test2.fixed_width.txt',
  #                    :format => :fixed_width,
  #                    :skip => 1,
  #                    :schema => [[ 'header4', 10, { :type => :string }  ],
  #                                [  'spacer',  1 ],
  #                                [  'header5', 10, { :type => :string } ],
  #                                [  'spacer',  12 ],
  #                                [  'header6', 10, { :type => :string } ]])
  attr_reader :schema
  
  # If you somehow already defined a fixed-width schema (so you can re-use it?), specify it here.
  # @return [String,Symbol]
  attr_reader :schema_name
  
  # A proc that decides whether to include a row. Previously passed as +:select+.
  # @return [Proc]
  attr_reader :pre_select
  
  # A proc that decides whether to include a row. Previously passed as +:reject+.
  # @return [Proc]
  attr_reader :pre_reject

  # An object that responds to #rejects?(row) and #correct!(row). Applied after creating +row_hash+.
  #
  # * #rejects?(row) - if row should be treated like it doesn't exist
  # * #correct!(row) - destructively update a row to fix something
  #
  # See the Errata library at https://github.com/seamusabshere/errata for an example implementation.
  #
  # @return [Hash]
  attr_reader :errata
  
  # The format of the source file. Can be specified as: :xlsx, :xls, :delimited (aka :csv), :ods, :fixed_width, :html, :xml, :yaml
  #
  # Note: treats all +docs.google.com+ and +spreadsheets.google.com+ URLs as +:delimited+.
  #
  # Default: guessed from file extension (which is usually the same as the URL, but sometimes not if you pick out a specific file from an archive)
  #
  # @return [Hash]
  attr_reader :format

  # Options passed by the user that may be passed through to the underlying parsing library.
  # @return [Hash]
  attr_reader :other_options

  # Create a new RemoteTable, which is an Enumerable.
  #
  # Options are set at creation using any of the attributes listed... RDoc will say they're "read-only" because you can't set/change them after creation.
  #
  # Does not immediately download/parse... it's lazy-loading.
  #
  # @overload initialize(settings)
  #   @param [Hash] settings Settings including +:url+.
  #
  # @overload initialize(url, settings)
  #   @param [String] url The URL to the local or remote file.
  #   @param [Hash] settings Settings.
  #
  # @example Open an XLSX
  #   RemoteTable.new('http://www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx')
  #
  # @example Open a CSV inside a ZIP file
  #   RemoteTable.new 'http://www.epa.gov/climatechange/emissions/downloads10/2010-Inventory-Annex-Tables.zip',
  #                   :filename => 'Annex Tables/Annex 3/Table A-93.csv',
  #                   :skip => 1,
  #                   :pre_select => proc { |row| row['Vehicle Age'].strip =~ /^\d+$/ }
  def initialize(*args)
    @download_count_mutex = ::Mutex.new
    @extend_bang_mutex = ::Mutex.new

    @cache = []
    @download_count = 0

    settings = args.last.is_a?(::Hash) ? args.last.symbolize_keys : {}

    @url = if args.first.is_a? ::String
      args.first
    else
      grab settings, :url
    end
    @format = RemoteTable.guess_format grab(settings, :format)
    if GOOGLE_DOCS_SPREADSHEET.any? { |regex| regex =~ url }
      @url = RemoteTable.google_spreadsheet_csv_url url
      @format = :delimited
    end

    @headers = grab settings, :headers
    if headers.is_a?(::Array) and headers.any?(&:blank?)
      raise ::ArgumentError, "[remote_table] If you specify headers, none of them can be blank"
    end

    @compression = grab(settings, :compression) || RemoteTable.guess_compression(url)
    @packing = grab(settings, :packing) || RemoteTable.guess_packing(url)

    @streaming = grab settings, :streaming
    @warn_on_multiple_downloads = grab settings, :warn_on_multiple_downloads
    @delimiter = grab settings, :delimiter
    @sheet = grab settings, :sheet
    @keep_blank_rows = grab settings, :keep_blank_rows
    @form_data = grab settings, :form_data
    @skip = grab settings, :skip
    @encoding = grab settings, :encoding
    @row_xpath = grab settings, :row_xpath
    @column_xpath = grab settings, :column_xpath
    @row_css = grab settings, :row_css
    @column_css = grab settings, :column_css
    @glob = grab settings, :glob
    @filename = grab settings, :filename
    @cut = grab settings, :cut
    @crop = grab settings, :crop
    @schema = grab settings, :schema
    @schema_name = grab settings, :schema_name
    @pre_select = grab settings, :pre_select
    @pre_reject = grab settings, :pre_reject
    @errata = grab settings, :errata

    @other_options = settings
    
    @local_copy = LocalCopy.new self
  end

  # Yield each row.
  #
  # @return [nil]
  #
  # @yield [Hash,Array] A hash or an array depending on whether the RemoteTable has named headers (column names).
  def each
    extend!
    if fully_cached?
      cache.each do |row|
        yield row
      end
    else
      mark_download!
      memo = _each do |row|
        # transformer.transform(row).each do |virtual_row|
        virtual_row = row
          virtual_row.row_hash = ::HashDigest.hexdigest row
          if errata
            next if errata.rejects? virtual_row
            errata.correct! virtual_row
          end
          next if pre_select and !pre_select.call(virtual_row)
          next if pre_reject and pre_reject.call(virtual_row)
          unless streaming
            cache.push virtual_row
          end
          yield virtual_row
        # end
      end
      unless streaming
        fully_cached!
      end
      memo
    end
    nil
  end

  # @deprecated
  alias :each_row :each
  
  # @return [Array<Hash,Array>] All rows.
  def to_a
    if fully_cached?
      cache.dup
    else
      map { |row| row }
    end
  end

  # @deprecated
  alias :rows :to_a
  
  # Get a row by row number. Zero-based.
  #
  # @return [Hash,Array]
  def [](row_number)
    if fully_cached?
      cache[row_number]
    else
      to_a[row_number]
    end
  end
  
  # Clear the row cache in case it helps your GC.
  #
  # @return [nil]
  def free
    @fully_cached = false
    cache.clear
    nil
  end

  private
  
  def mark_download!
    @download_count_mutex.synchronize do
      @download_count += 1
    end
    if warn_on_multiple_downloads and download_count > 1
      ::Kernel.warn "[remote_table] #{url} has been downloaded #{download_count} times."
    end
  end 
  
  def fully_cached!
    @fully_cached = true
  end
  
  def fully_cached?
    !!@fully_cached
  end

  def transliterate_to_utf8(str)
    if str.is_a?(::String)
      ::ActiveSupport::Inflector.transliterate str
    end
  end

  def assume_utf8(str)
    if str.is_a?(::String) and ::RUBY_VERSION >= '1.9'
      str.encode! EXTERNAL_ENCODING
    else
      str
    end
  end

  def grab(settings, k)
    user_specified = false
    memo = nil
    if (old_names = OLD_SETTING_NAMES[k]) and old_names.any? { |old_k| settings.has_key?(old_k) }
      user_specified = true
      memo = old_names.map { |old_k| settings.delete(old_k) }.compact.first
    end
    if settings.has_key?(k)
      user_specified = true
      memo = settings.delete k
    end
    if not user_specified and DEFAULT.has_key?(k)
      memo = DEFAULT[k]
    end
    if memo and (valid = VALID[k]) and not valid.include?(memo.to_sym)
      raise ::ArgumentError, %{[remote_table] #{k.inspect} => #{memo.inspect} is not a valid setting. Valid settings are #{valid.inspect}.}
    end
    memo
  end

  def extend!
    return if @extend_bang
    @extend_bang_mutex.synchronize do
      return if @extend_bang
      @extend_bang = true
      format_module = if format
        RemoteTable.const_get format.to_s.camelcase
      elsif format = RemoteTable.guess_format(local_copy.path)
        @format = format
        RemoteTable.const_get format.to_s.camelcase
      else
        Delimited
      end
      extend format_module
      after_extend if respond_to?(:after_extend)
    end
  end
end
