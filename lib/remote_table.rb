require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/hash
  active_support/core_ext/string
  active_support/core_ext/module
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3

class RemoteTable
  autoload :Format, 'remote_table/format'
  autoload :Properties, 'remote_table/properties'
  autoload :LocalFile, 'remote_table/local_file'
  autoload :Transformer, 'remote_table/transformer'

  # singletons
  autoload :Cleaner, 'remote_table/cleaner'
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
    if args.first.is_a? ::String
      @url = args.first.dup
    else
      @url = @options['url'] || @options[:url]
    end
    # deprecated
    if options[:transform]
      transformer.legacy_transformer = options[:transform][:class].new options[:transform].except(:class)
      transformer.legacy_transformer.add_hints! @options
    end
    @options.stringify_keys!
    @url.freeze
    @options.freeze
    at_exit { ::RemoteTable.cleaner.cleanup }
  end
  
  def each(&blk)
    format.each do |row|
      row['row_hash'] = ::RemoteTable.hasher.hash row
      # allow the transformer to return multiple "virtual rows" for every real row
      transformer.transform(row).each do |virtual_row|
        if properties.errata
          next if properties.errata.rejects? virtual_row
          properties.errata.correct! virtual_row
        end
        next if properties.select and !properties.select.call(virtual_row)
        next if properties.reject and properties.reject.call(virtual_row)
        yield virtual_row
      end
    end
  end
  
  # Get a row by row number
  def [](row_number)
    to_a[row_number]
  end
  
  # Get the whole row array back
  def rows
    to_a
  end
  
  # Used internally as a sort of garbage collector.
  def self.cleaner
    Cleaner.instance
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
end
