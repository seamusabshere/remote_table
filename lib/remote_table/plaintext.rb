require 'fileutils'
require 'unix_utils'

class RemoteTable
  # Helper methods that act on plaintext files before they are parsed
  module Plaintext
    class << self
      # @private
      # Code for the soft hyphen, often inserted by MS Office (html: &shy;)
      def soft_hyphen(encoding)
        case encoding
        when /775/, /85[02578]/
          '\xF0'
        when /utf-?8/i
          '\xc2\xad'
        else # iso-8859-1, latin1, windows-1252, etc...
          '\xad'
        end
      end
    end

    # UTF-8 byte order mark
    UTF8_BOM = '\xef\xbb\xbf'
    EOL_TO_UNIX = 's/\r\n|\n|\r/\n/g'

    # Remove bytes that are both useless and harmful in the vast majority of cases.
    def delete_harmful!
      harmful = [ Plaintext.soft_hyphen(encoding), UTF8_BOM ]
      local_copy.in_place :perl, "s/#{harmful.join('//g; s/')}//g"
    end

    # No matter what the file encoding is SUPPOSED to be, run it through the system iconv binary to make sure it's UTF-8
    #
    # @example
    #   iconv -c -t UTF-8//TRANSLIT -f WINDOWS-1252
    def transliterate_whole_file_to_utf8!
      if ::UnixUtils.available?('iconv')
        local_copy.in_place :iconv, RemoteTable::EXTERNAL_ENCODING_ICONV, encoding
      else
        ::Kernel.warn %{[remote_table] iconv not available in your $PATH, not performing transliteration}
      end
      # now that we've force-transliterated to UTF-8, act as though this is what the user had specified
      @encoding = RemoteTable::EXTERNAL_ENCODING
    end
    
    # No matter what the EOL are SUPPOSED to be, run it through Perl with a regex that will convert all EOLS to \n
    #
    # @example
    #   perl -pe 's/\r\n|\n|\r/\n/g'
    def convert_eol_to_unix!
      local_copy.in_place :perl, EOL_TO_UNIX
    end
    
    # If the user has specified :skip, use tail
    #
    # @example :skip => 6
    #   tail +7
    def skip_rows!
      if skip > 0
        local_copy.in_place :tail, "+#{skip + 1}"
      end
    end
    
    # If the user has specified :crop, use a combination of tail and head
    #
    # @example :crop => (184..263)
    #   tail +184 | head 80
    def crop_rows!
      if crop
        local_copy.in_place :tail, "+#{crop.first}"
        local_copy.in_place :head, (crop.last - crop.first + 1)
      end
    end
    
    # If the user has specified :cut, use cut
    #
    # @example :cut => '13-'
    #   cut -c 13-
    def cut_columns!
      if cut
        local_copy.in_place :cut, cut
      end
    end
  end
end
