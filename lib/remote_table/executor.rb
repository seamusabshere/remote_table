require 'singleton'
require 'escape'
require 'fileutils'
class RemoteTable
  class Executor
    include ::Singleton
    def bang(path, cmd)
      tmp_path = "#{path}.bang.#{rand}"
      backtick_with_reporting "/bin/cat #{::Escape.shell_single_word path} | #{cmd} > #{::Escape.shell_single_word tmp_path}"
      ::FileUtils.mv tmp_path, path
    end

    def backtick_with_reporting(cmd)
      cmd = cmd.gsub /[ ]*\n[ ]*/m, ' '
      output = `#{cmd}`
      if not $?.success?
        raise %{
From the remote_table gem...

Command failed:
#{cmd}

Output:
#{output}
}
      end
    end
  end
end
