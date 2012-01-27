class RemoteTable
  class Transformer
    extend ::ActiveSupport::Memoizable
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
      if transform_options = t.config.user_specified_options[:transform]
        transform_options = transform_options.symbolize_keys
        transform_options[:class].new transform_options.except(:class)
      end
    end
    memoize :legacy_transformer
  end
end
