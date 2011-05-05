require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/hash
  active_support/core_ext/string
  active_support/core_ext/module
  active_support/core_ext/array
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3

class Hash
  attr_accessor :row_hash
end

class Array
  attr_accessor :row_hash
end

class RemoteTable
  autoload :Format, 'remote_table/format'
  autoload :Properties, 'remote_table/properties'
  autoload :LocalFile, 'remote_table/local_file'
  autoload :Transformer, 'remote_table/transformer'

  # singletons
  autoload :Executor, 'remote_table/executor'
  autoload :Hasher, 'remote_table/hasher'
  
  # Legacy
  class Transform
    def self.row_hash(row)
      ::RemoteTable.hasher.hash row
    end
  end

  include ::Enumerable
  
  attr_reader :url
  attr_reader :options
  
  # Create a new RemoteTable.
  #
  #     RemoteTable.new(url, options = {})
  #
  # New syntax:
  #     RemoteTable.new('www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', 'foo' => 'bar')
  # Old syntax:
  #     RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :foo => 'bar')
  #
  # See the <tt>Properties</tt> object for the sorts of options you can pass.
  def initialize(*args)
    @options = args.last.is_a?(::Hash) ? args.last.dup : {}
    @options.stringify_keys!
    @url = if args.first.is_a? ::String
      args.first.dup
    else
      @options['url'].dup
    end
    @url.freeze
    @options.freeze
  end
  
  # not thread safe
  def each(&blk)
    if fully_cached?
      cache.each(&blk)
    else
      mark_download!
      retval = format.each do |row|
        row.row_hash = ::RemoteTable.hasher.hash row
        transformer.transform(row).each do |virtual_row|
          if properties.errata
            next if properties.errata.rejects? virtual_row
            properties.errata.correct! virtual_row
          end
          next if properties.select and !properties.select.call(virtual_row)
          next if properties.reject and properties.reject.call(virtual_row)
          cache.push virtual_row unless properties.streaming
          yield virtual_row
        end
      end
      fully_cached! unless properties.streaming
      retval
    end
  end
  alias :each_row :each
  
  def to_a
    if fully_cached?
      cache.dup
    else
      map { |row| row }
    end
  end
  alias :rows :to_a
  
  # Get a row by row number
  def [](row_number)
    if fully_cached?
      cache[row_number]
    else
      to_a[row_number]
    end
  end
  
  # clear the row cache to save memory
  def free
    cache.clear
    ::GC.start
    nil
  end
  
  # Used internally to execute stuff in shells.
  def self.executor
    Executor.instance
  end
  
  # Used internally to create unique hashes of rows.
  def self.hasher
    Hasher.instance
  end
  
  # Used internally to access to a downloaded copy of the file
  def local_file
    @local_file ||= LocalFile.new self
  end
  
  # Used internally to access to the properties of the table, either set by the user or implied
  def properties
    @properties ||= Properties.new self
  end
  
  # Used internally to access to the driver that reads the format
  def format
    @format ||= properties.format.new self
  end
  
  # Used internally to acess the transformer (aka parser).
  def transformer
    @transformer ||= Transformer.new self
  end
  
  attr_reader :download_count
  
  private
  
  def mark_download!
    @download_count ||= 0
    @download_count += 1
    if properties.warn_on_multiple_downloads and download_count > 1
      $stderr.puts "[remote_table] Warning: #{url} has been downloaded #{download_count} times."
    end
  end 
  
  def fully_cached!
    @fully_cached = true
  end
  
  def fully_cached?
    !!@fully_cached
  end
  
  def cache
    @cache ||= []
  end
end
