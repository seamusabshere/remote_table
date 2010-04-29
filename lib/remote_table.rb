require 'digest/md5'
require 'iconv'
require 'uri'
require 'tmpdir'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/object/blank
  active_support/core_ext/string/inflections
  active_support/core_ext/array/wrap
  active_support/core_ext/hash/except
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3
require 'fastercsv'
require 'slither'
require 'roo'
I_KNOW_I_AM_USING_AN_OLD_AND_BUGGY_VERSION_OF_LIBXML2 = true
require 'nokogiri'
require 'remote_table/transform'
require 'remote_table/request'
require 'remote_table/package'
require 'remote_table/file'
require 'remote_table/file/csv'
require 'remote_table/file/fixed_width'
require 'remote_table/file/roo_spreadsheet'
require 'remote_table/file/ods'
require 'remote_table/file/xls'
require 'remote_table/file/html'

class RemoteTable
  attr_accessor :request, :package, :file, :transform
  attr_accessor :table
  
  include Enumerable
  
  def initialize(bus)
    @transform = Transform.new(bus)
    @package = Package.new(bus)
    @request = Request.new(bus)
    @file = File.new(bus)
  end
  
  def each
    finish_table! unless table
    table.each_row { |row| yield row }
  end
  alias :each_row :each
  
  def to_a
    cache_rows! if @_row_cache.nil?
    @_row_cache
  end
  alias :rows :to_a
  
  def <=>(other)
    raise "Not implemented"
  end

  protected
  
  # TODO this should probably live somewhere else
  def self.backtick_with_reporting(cmd)
    cmd = cmd.gsub /\s+/m, ' '
    cmd = cmd + ' 2>&1' unless cmd.include? '2>'
    output = `#{cmd}`
    unless $?.success?
      raise %{
From the remote_table gem...

Command failed:
#{cmd}

Output:
#{output}
}
    end
  end
  
  private
  
  def finish_table!
    package_path = request.download
    file_path = package.stage(package_path)
    raw_table = file.tabulate(file_path)
    self.table = transform.apply(raw_table) # must return something that responds to each_row
  end
  
  def cache_rows!
    @_row_cache = []
    each_row { |row| @_row_cache << row }
  end
end
