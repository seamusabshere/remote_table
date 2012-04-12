class RemoteTable
  class Transformer
    attr_reader :t
    def initialize(t)
      @t = t
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
      memo = if (transform_options = t.config.user_specified_options[:transform])
        transform_options = transform_options.symbolize_keys
        transform_options[:class].new transform_options.except(:class)
      end
      @legacy_transformer = [memo]
      memo
    end
  end
end
