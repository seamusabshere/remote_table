class RemoteTable
  class Transformer
    attr_reader :t
    attr_accessor :legacy_transformer
    def initialize(t)
      @t = t
    end
    # eventually this will support a different way of specifying a transformer
    def transform(row)
      if legacy_transformer
        legacy_transformer.apply row
      else
        [ row ]
      end
    end
  end
end
