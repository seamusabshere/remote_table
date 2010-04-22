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
  
  def initialize(bus)
    @transform = Transform.new(bus)
    @package = Package.new(bus)
    @request = Request.new(bus)
    @file = File.new(bus)
  end
  
  def each_row
    finish_table! unless table
    table.each_row { |row| yield row }
  end
  
  def rows
    cache_rows! if @_row_cache.nil?
    @_row_cache
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
