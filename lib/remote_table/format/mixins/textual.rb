require 'fileutils'
class RemoteTable
  class Format
    module Textual      
      USELESS_CHARACTERS = [
        '\xef\xbb\xbf',   # UTF-8 byte order mark
        '\xc2\xad',       # soft hyphen, often inserted by MS Office (html: &shy;)
      ]
      def remove_useless_characters!
        Utils.in_place t.local_file.path, 'perl', '-pe', "s/#{USELESS_CHARACTERS.join '//g; s/'}//g"
        if t.properties.internal_encoding =~ /windows.?1252/i
          # soft hyphen again, as I have seen it appear in windows 1252
          Utils.in_place t.local_file.path, 'perl', '-pe', 's/\xad//g'
        end
      end
      
      def transliterate_whole_file_to_utf8!
        Utils.in_place t.local_file.path, 'iconv', '-c', '-f', t.properties.internal_encoding, '-t', t.properties.external_encoding_iconv, :ignore_error => true
        t.properties.update :encoding => t.properties.external_encoding
      end
      
      def fix_newlines!
        Utils.in_place t.local_file.path, 'perl', '-pe', 's/\r\n|\n|\r/\n/g'
      end
      
      def skip_rows!
        return unless t.properties.skip > 0
        Utils.in_place t.local_file.path, 'tail', '-n', "+#{t.properties.skip + 1}"
      end
      
      def crop_rows!
        return unless t.properties.crop
        Utils.in_place t.local_file.path, 'tail', '-n', "+#{t.properties.crop.first}"
        Utils.in_place t.local_file.path, 'head', '-n', (t.properties.crop.last - t.properties.crop.first + 1).to_s
      end
      
      def cut_columns!
        return unless t.properties.cut
        Utils.in_place t.local_file.path, 'cut', '-c', t.properties.cut.to_s
      end
    end
  end
end
