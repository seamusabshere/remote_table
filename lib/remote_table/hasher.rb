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
      row = row.dup
      row.stringify_keys!
      str = row.keys.sort.map do |k|
        row[k].to_query k
      end.join('&')
      ::Digest::MD5.hexdigest str
    end
  end
end
