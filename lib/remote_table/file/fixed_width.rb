class RemoteTable
  module FixedWidth
    def each_row(&block)
      backup_file!
      convert_file_to_utf8!
      crop_rows!
      skip_rows!
      cut_columns!
      a = Slither.parse(path, schema_name)
      a[:rows].each do |hash|
        hash.reject! { |k, v| k.blank? }
        yield hash if keep_blank_rows or hash.any? { |k, v| v.present? }
      end
    ensure
      restore_file!
    end
  end
end
