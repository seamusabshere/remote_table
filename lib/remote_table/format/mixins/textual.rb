require 'fileutils'
require 'escape'
class RemoteTable
  class Format
    module Textual      
      USELESS_CHARACTERS = [
        '\xef\xbb\xbf',   # UTF-8 byte order mark
        '\xc2\xad',       # soft hyphen, often inserted by MS Office (html: &shy;)
        '\xad',
        # '\xa0'
      ]
      def remove_useless_characters!
        ::RemoteTable.executor.bang t.local_file.path, "perl -pe 's/#{USELESS_CHARACTERS.join '//g; s/'}//g'"
      end
      
      def skip_rows!
        return unless t.properties.skip > 0
        ::RemoteTable.executor.bang t.local_file.path, "tail -n +#{t.properties.skip + 1}"
      end
      
      def crop_rows!
        return unless t.properties.crop
        ::RemoteTable.executor.bang t.local_file.path, "tail -n +#{::Escape.shell_single_word t.properties.crop.first.to_s} | head -n #{t.properties.crop.last - t.properties.crop.first + 1}"
      end
      
      def cut_columns!
        return unless t.properties.cut
        ::RemoteTable.executor.bang t.local_file.path, "cut -c #{::Escape.shell_single_word t.properties.cut.to_s}"
      end
    end
  end
end
