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
  autoload :Cleaner, 'remote_table/cleaner'
  autoload :Executor, 'remote_table/executor'
  autoload :Hasher, 'remote_table/hasher'
  
  def self.cleaner
    Cleaner.instance
  end
  
  def self.executor
    Executor.instance
  end
  
  def self.hasher
    Hasher.instance
  end
  
  # Legacy
  class Transform
    def self.row_hash(row)
      ::RemoteTable.hasher.hash row
    end
  end

  include ::Enumerable
  
  attr_reader :url
  attr_reader :options
  
  # New syntax:
  #     t = RemoteTable.new('www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :foo => :bar)
  # Old syntax:
  #     t = RemoteTable.new(:url => 'www.customerreferenceprogram.org/uploads/CRP_RFP_template.xlsx', :foo => :bar)
  def initialize(*args)
    if args.length == 2
      @options = args[1].dup
    else
      @options = args[0].dup
    end
    @options.stringify_keys!
    if args.length == 2
      @url = args[0].dup
    else
      @url = @options['url']
    end
    @url.freeze
    @options.freeze
    at_exit { ::RemoteTable.cleaner.cleanup }
  end
  
  def each(&blk)
    format.each do |row|
      next if properties.select and !properties.select.call(row)
      next if properties.reject and properties.reject.call(row)
      yield row
    end
  end
  
  # def to_a_with_caching
  #   @to_a ||= to_a_without_caching
  # end
  # alias_method_chain :to_a, :caching
  # alias_method :to_a_without_caching, :to_a
  # alias_method :to_a, :to_a_with_caching
  
  # Get a row by row number
  def [](row_number)
    to_a[row_number]
  end
  
  # Get the whole row array back
  def rows
    to_a
  end
      
  # Access to a downloaded copy of the file
  def local_file
    @local_file ||= LocalFile.new self
  end
  
  # Access to the properties of the table, either set by the user or implied
  def properties
    @properties ||= Properties.new self
  end
  
  # Access to the format that reads the format
  def format
    @format ||= properties.format.new self
  end
end
