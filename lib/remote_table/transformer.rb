class RemoteTable
  class Transformer
    attr_reader :t
    def initialize(t)
      @t = t
      @legacy_transformer_mutex = ::Mutex.new
    end
    # eventually this will support a different way of specifying a transformer
    def transform(row)
      if legacy_transformer
        ::Array.wrap legacy_transformer.apply(row)
      else
        [row]
      end
    end
    def legacy_transformer
      return @legacy_transformer[0] if @legacy_transformer.is_a?(::Array)
      @legacy_transformer_mutex.synchronize do
        return @legacy_transformer[0] if @legacy_transformer.is_a?(::Array)
        memo = if (transform_settings = t.transform_settings)
          transform_settings = transform_settings.symbolize_keys
          transform_settings[:class].new transform_settings.except(:class)
        end
        @legacy_transformer = [memo]
        memo
      end
    end
  end
end
