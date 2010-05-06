class RemoteTable
  class Transform
    attr_accessor :select, :reject, :transform_class, :transform_options, :transform, :raw_table
    attr_accessor :errata
    
    def initialize(bus)
      if transform_params = bus.delete(:transform)
        @transform_class = transform_params.delete(:class)
        @transform_options = transform_params
        @transform = @transform_class.new(@transform_options)
        @transform.add_hints!(bus)
      end
      @select = bus[:select]
      @reject = bus[:reject]
      @errata = bus[:errata]
    end
    
    # the null transformation
    def apply(raw_table)
      self.raw_table = raw_table
      self
    end
    
    # - convert OrderedHash to a Hash (otherwise field ordering will be saved)
    # - dump it
    # - digest it
    def self.row_hash(row)
      Digest::MD5.hexdigest Marshal.dump(Hash.new.replace(row))
    end
    
    def each_row(&block)
      raw_table.each_row do |row|
        row['row_hash'] = self.class.row_hash(row)
        virtual_rows = transform ? transform.apply(row) : row # allow transform.apply(row) to return multiple rows
        Array.wrap(virtual_rows).each do |virtual_row|
          if errata
            next if errata.rejects? virtual_row
            errata.correct! virtual_row
          end
          next if select and !select.call(virtual_row)
          next if reject and reject.call(virtual_row)
          yield virtual_row
        end
      end
    end
  end
end
