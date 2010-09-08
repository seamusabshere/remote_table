require 'digest/md5'
require 'uri'
require 'tmpdir'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/string/conversions
  active_support/core_ext/object/blank
  active_support/core_ext/string/inflections
  active_support/core_ext/array/wrap
  active_support/core_ext/hash/except
  active_support/core_ext/class/attribute_accessors
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ActiveSupport::VERSION::MAJOR == 3
require 'fastercsv'
require 'escape'
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
require 'remote_table/file/xlsx'
require 'remote_table/file/html'

class RemoteTable
  cattr_accessor :paths_for_removal
  class << self
    def cleanup
      paths_for_removal.each do |path|
        FileUtils.rm_rf path
        paths_for_removal.delete path
      end if paths_for_removal.is_a?(Array)
    end
    
    def remove_at_exit(path)
      self.paths_for_removal ||= Array.new
      paths_for_removal.push path
    end
  end

  attr_accessor :request, :package, :file, :transform
  attr_accessor :table
  
  include Enumerable
  
  def initialize(bus)
    @transform = Transform.new(bus)
    @package = Package.new(bus)
    @request = Request.new(bus)
    @file = File.new(bus)
    at_exit { RemoteTable.cleanup }
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
  
  def self.bang(path, cmd)
    tmp_path = "#{path}.tmp"
    RemoteTable.backtick_with_reporting "cat #{Escape.shell_single_word path} | #{cmd} > #{Escape.shell_single_word tmp_path}"
    FileUtils.mv tmp_path, path
  end
  
  # TODO this should probably live somewhere else
  def self.backtick_with_reporting(cmd)
    cmd = cmd.gsub /[ ]*\n[ ]*/m, ' '
    output = `#{cmd}`
    if not $?.success?
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
