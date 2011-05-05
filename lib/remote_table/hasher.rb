require 'singleton'
require 'digest/md5'
require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/hash/keys
  active_support/core_ext/object/to_query
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3
class RemoteTable
  class Hasher
    include ::Singleton
    def hash(row)
      str = if row.is_a?(::Array)
        tmp_ary = []
        row.each_with_index do |v, i|
          tmp_ary.push v.to_query(i.to_s)
        end
        tmp_ary
      else
        row.stringify_keys.keys.sort.map do |k|
          row[k].to_query k
        end
      end.join('&')
      ::Digest::MD5.hexdigest str
    end
  end
end
