class RemoteTable
  # Parses plaintext fixed-width files using https://github.com/seamusabshere/fixed_width
  module FixedWidth
    def self.extended(base)
      base.extend Plaintext
    end

    TRAP_EVERYTHING = proc { |_| true }

    # @private
    def after_extend
      @fixed_width_parser_mutex = ::Mutex.new
      @definition_mutex = ::Mutex.new
    end

    def _each
      require 'fixed_width-multibyte'

      delete_harmful!
      convert_eol_to_unix!
      transliterate_whole_file_to_utf8!
      crop_rows!
      skip_rows!
      cut_columns!

      fixed_width_parser.parse[:rows].each do |row|
        some_value_present = false
        hash = ::ActiveSupport::OrderedHash.new
        row.each do |k, v|
          v = v.to_s.strip
          if not some_value_present and not keep_blank_rows and v.present?
            some_value_present = true
          end
          hash[k] = v
        end
        if some_value_present or keep_blank_rows
          yield hash
        end
      end
    ensure
      local_copy.cleanup
    end

    private
    
    def fixed_width_parser
      @fixed_width_parser || @fixed_width_parser_mutex.synchronize do
        @fixed_width_parser ||= begin
          if ::FixedWidth::Section.private_instance_methods.map(&:to_sym).include?(:unpacker)
            raise ::RuntimeError, "[remote_table] You need to use exclusively the fixed_width-multibyte library https://github.com/seamusabshere/fixed_width"
          end
          ::FixedWidth::Parser.new definition, local_copy.encoded_io
        end
      end
    end
    
    def definition
      @definition || @definition_mutex.synchronize do
        @definition ||= if schema_name.is_a?(::String) or schema_name.is_a?(::Symbol)
          ::FixedWidth.send :definition, schema_name
        elsif schema.is_a?(::Array)
          ::FixedWidth.define("remote_table-fixed_with-#{::Kernel.rand}") do |d|
            d.rows do |row|
              row.trap(&TRAP_EVERYTHING)
              schema.each do |name, width, options|
                name = name.to_s
                if name == 'spacer'
                  row.spacer width
                else
                  row.column name, width, options
                end
              end
            end
          end
        else
          raise ::ArgumentError, "[remote_table] Expecting :schema_name to be a String or Symbol, or :schema to be an Array"
        end
      end
    end
  end
end
