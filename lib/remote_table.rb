if ::RUBY_VERSION < '1.9' and $KCODE != 'UTF8'
  ::Kernel.warn "[remote_table] Ruby 1.8 detected, setting $KCODE to UTF8 so that ActiveSupport::Multibyte works properly."
  $KCODE = 'UTF8'
end

require 'thread'

require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR >= 3
  require 'active_support/core_ext'
end
require 'hash_digest'

require 'remote_table/format'
require 'remote_table/config'
require 'remote_table/local_copy'
require 'remote_table/transformer'

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

# Open local or remote XLSX, XLS, ODS, CSV and fixed-width files.
class RemoteTable
  # @private
  # Here to support legacy code.
  class Transform
    def self.row_hash(row)
      ::HashDigest.hexdigest row
    end
  end

  include ::Enumerable
  
  # The URL of the local or remote file.
  #
  # * Local: "file:///Users/myuser/Desktop/holidays.csv"
  # * Remote: "http://data.brighterplanet.com/countries.csv"
  #
  # @return [String]
  attr_reader :url

  # The remote table configuration. Mostly for internal use.
  # @return [RemoteTable::Config]
  attr_reader :config

  # A cache of rows, created unless +:streaming+ is enabled.
  # @return [Array<Hash,Array>]
  attr_reader :cache

  # How many times this file has been downloaded. RemoteTable will emit a warning if you download it more than once.
  # @return [Integer]
  attr_reader :download_count

  # Create a new RemoteTable, which is an Enumerable.
  #
  # Does not immediately download/parse... it's lazy-loading.
  #
  # @overload initialize(config)
  #   @param [Hash] config Settings including +:url+.
  #
  # @overload initialize(url, config)
  #   @param [String] url The URL to the local or remote file.
  #   @param [Hash] config Settings.
  #
  # @example Open an XLSX
  #   RemoteTable.new('http://www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :foo => 'bar')
  #
  # @see RemoteTable::Config What configuration settings are available.
  def initialize(*args)
    @cache = []
    @download_count = 0
    options = args.last.is_a?(::Hash) ? args.last.symbolize_keys : {}
    @url = if args.first.is_a? ::String
      args.first.dup
    else
      options[:url].dup
    end
    @config = Config.new self, options
    @local_copy_mutex = ::Mutex.new
    @format_mutex = ::Mutex.new
    @transformer_mutex = ::Mutex.new
    @download_count_mutex = ::Mutex.new
  end
  
  # Yield each row.
  #
  # @yield [Hash,Array] A hash or an array depending on whether the RemoteTable has named headers (column names).
  def each
    if fully_cached?
      cache.each do |row|
        yield row
      end
    else
      mark_download!
      memo = format.each do |row|
        transformer.transform(row).each do |virtual_row|
          virtual_row.row_hash = ::HashDigest.hexdigest row
          if config.errata
            next if config.errata.rejects? virtual_row
            config.errata.correct! virtual_row
          end
          next if config.select and !config.select.call(virtual_row)
          next if config.reject and config.reject.call(virtual_row)
          unless config.streaming
            cache.push virtual_row
          end
          yield virtual_row
        end
      end
      unless config.streaming
        fully_cached!
      end
      memo
    end
  end
  alias :each_row :each
  
  # @return [Array<Hash,Array>] All rows.
  def to_a
    if fully_cached?
      cache.dup
    else
      map { |row| row }
    end
  end

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
  
  # Used internally to access to a downloaded copy of the file.
  def local_copy
    @local_copy || @local_copy_mutex.synchronize do
      @local_copy ||= LocalCopy.new self
    end
  end
  
  # Used internally to access to the driver that reads the format
  def format
    @format || @format_mutex.synchronize do
      @format ||= config.format.new self
    end
  end
  
  # Used internally to access the transformer (aka parser).
  def transformer
    @transformer || @transformer_mutex.synchronize do
      @transformer ||= Transformer.new self
    end
  end
  
  private
  
  def mark_download!
    @download_count_mutex.synchronize do
      @download_count += 1
    end
    if config.warn_on_multiple_downloads and download_count > 1
      ::Kernel.warn "[remote_table] #{url} has been downloaded #{download_count} times."
    end
  end 
  
  def fully_cached!
    @fully_cached = true
  end
  
  def fully_cached?
    !!@fully_cached
  end
end
