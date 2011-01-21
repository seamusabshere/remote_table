require 'singleton'
require 'digest/md5'
class RemoteTable
  class Hasher
    include ::Singleton
    def hash(row)
      normalized_hash = if RUBY_VERSION >= '1.9'
        row.keys.sort.inject(::Hash.new) do |memo, k|
          normalized_k = k.to_s.toutf8
          normalized_v = row[k].respond_to?(:to_s) ? row[k].to_s.toutf8 : row[k]
          memo[normalized_k] = normalized_v
          memo
        end
      else
        ::Hash.new.replace(row)
      end
      # sabshere 1/21/11 may currently break across versions of ruby
      # ruby-1.8.7-p174 > Marshal.dump({'a' => '1'})
      #  => "\004\b{\006\"\006a\"\0061" 
      # ruby-1.9.2-p0 > Marshal.dump({'a' => '1'})
      # => "\x04\b{\x06I\"\x06a\x06:\x06ETI\"\x061\x06;\x00T"
      ::Digest::MD5.hexdigest ::Marshal.dump(normalized_hash)
    end
  end
end
