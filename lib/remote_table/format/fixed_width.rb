class RemoteTable
  class Format
    class FixedWidth < Format
      include Textual
      def each(&blk)
        require 'fixed_width-multibyte'

        remove_useless_characters!
        fix_newlines!
        transliterate_whole_file_to_utf8!
        crop_rows!
        skip_rows!
        cut_columns!
        parser.parse[:rows].each do |row|
          row.reject! { |k, v| k.blank? }
          row.each do |k, v|
            row[k] = v.strip
          end
          yield row if t.config.keep_blank_rows or row.any? { |k, v| v.present? }
        end
      ensure
        t.local_copy.cleanup
      end
      
      private
      
      def parser
        return @parser if @parser.is_a?(::FixedWidth::Parser)
        if ::FixedWidth::Section.private_instance_methods.map(&:to_sym).include?(:unpacker)
          raise ::RuntimeError, "You need a different (newer) version of the FixedWidth gem that supports multibyte encoding, sometime after https://github.com/timonk/fixed_width/pull/1 was incorporated"
        end
        @parser = ::FixedWidth::Parser.new definition, t.local_copy.encoded_io
      end
      
      def definition
        @definition ||= if t.config.schema_name.is_a?(::String) or t.config.schema_name.is_a?(::Symbol)
          ::FixedWidth.send :definition, t.config.schema_name
        elsif t.config.schema.is_a?(::Array)
          everything = lambda { |_| true }
          srand # in case this was forked by resque
          ::FixedWidth.define(rand.to_s) do |d|
            d.rows do |row|
              row.trap(&everything)
              t.config.schema.each do |name, width, options|
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
          raise ::ArgumentError, "expecting schema_name to be a String or Symbol, or schema to be an Array"
        end
      end
    end
  end
end
