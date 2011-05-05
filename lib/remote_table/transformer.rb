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
      return @legacy_transformer if @legacy_transformer
      return unless t.options['transform']
      transform_options = t.options['transform'].dup
      transform_options.stringify_keys!
      @legacy_transformer = transform_options['class'].new transform_options.except('class')
    end
  end
end
