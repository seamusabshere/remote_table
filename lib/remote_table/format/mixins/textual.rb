require 'fileutils'
require 'escape'
class RemoteTable
  class Format
    module Textual
      def convert_file_to_utf8!
        ::RemoteTable.executor.bang t.local_file.path, "iconv -c -f #{::Escape.shell_single_word t.properties.encoding} -t UTF-8"
      end
      
      USELESS_CHARACTERS = [
        '\xef\xbb\xbf',   # UTF-8 byte order mark
        '\xc2\xad'        # soft hyphen, often inserted by MS Office (html: &shy;)
      ]
      def remove_useless_characters!
        ::RemoteTable.executor.bang t.local_file.path, "perl -pe 's/#{USELESS_CHARACTERS.join '//g; s/'}//g'"
      end
      
      def skip_rows!
        return unless t.properties.skip > 0
        ::RemoteTable.executor.bang t.local_file.path, "tail -n +#{t.properties.skip + 1}"
      end
    end
  end
end
