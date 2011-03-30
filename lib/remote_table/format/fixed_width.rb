require 'slither'
class RemoteTable
  class Format
    class FixedWidth < Format
      include Textual
      def each(&blk)
        convert_file_to_utf8!
        remove_useless_characters!
        crop_rows!
        skip_rows!
        cut_columns!
        parser.parse[:rows].each do |hash|
          hash.reject! { |k, v| k.blank? }
          yield hash if t.properties.keep_blank_rows or hash.any? { |k, v| v.present? }
        end
      ensure
        delete_file!
      end
      private
      def parser
        @parser ||= ::Slither::Parser.new definition, t.local_file.path
      end
      def definition
        @definition ||= if t.properties.schema_name.is_a?(::String) or t.properties.schema_name.is_a?(::Symbol)
          ::Slither.send :definition, t.properties.schema_name
        elsif t.properties.schema.is_a?(::Array)
          everything = lambda { |_| true }
          ::Slither.define(rand.to_s) do |d|
            d.rows do |row|
              row.trap(&everything)
              t.properties.schema.each do |name, width, options|
                if name == 'spacer'
                  row.spacer width
                else
                  row.column name, width, options
                end
              end
            end
          end
        else
          raise "expecting schema_name to be a String or Symbol, or schema to be an Array"
        end
      end
    end
  end
end
