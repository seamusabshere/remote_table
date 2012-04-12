require 'fileutils'
class RemoteTable
  class Format
    module Textual      
      USELESS_CHARACTERS = [
        '\xef\xbb\xbf',   # UTF-8 byte order mark
        '\xc2\xad',       # soft hyphen, often inserted by MS Office (html: &shy;)
      ]
      def remove_useless_characters!
        t.local_file.in_place :perl, "s/#{USELESS_CHARACTERS.join('//g; s/')}//g"
        if t.config.internal_encoding =~ /windows.?1252/i
          # soft hyphen again, as I have seen it appear in windows 1252
          t.local_file.in_place :perl, 's/\xad//g'
        end
      end
      
      def transliterate_whole_file_to_utf8!
        t.local_file.in_place :iconv, t.config.external_encoding_iconv, t.config.internal_encoding
        t.config.user_specified_options[:encoding] = t.config.external_encoding
      end
      
      def fix_newlines!
        t.local_file.in_place :perl, 's/\r\n|\n|\r/\n/g'
      end
      
      def skip_rows!
        return unless t.config.skip > 0
        t.local_file.in_place :tail, "+#{t.config.skip + 1}"
      end
      
      def crop_rows!
        return unless t.config.crop
        t.local_file.in_place :tail, "+#{t.config.crop.first}"
        t.local_file.in_place :head, (t.config.crop.last - t.config.crop.first + 1)
      end
      
      def cut_columns!
        return unless t.config.cut
        t.local_file.in_place :cut, t.config.cut
      end
    end
  end
end
