require 'singleton'
require 'escape'
require 'fileutils'
require 'posix/spawn'

class RemoteTable
  class Executor
    include ::Singleton
    def bang(path, cmd)
      tmp_path = "#{path}.bang.#{rand}"
      backtick_with_reporting "cat #{::Escape.shell_single_word path} | #{cmd} > #{::Escape.shell_single_word tmp_path}"
      ::FileUtils.mv tmp_path, path
    end

    def backtick_with_reporting(cmd, raise_on_error = false)
      cmd = cmd.gsub /\n/m, ' '
      pid = ::POSIX::Spawn.spawn({ 'PATH' => '/usr/local/bin:/usr/bin:/bin' }, cmd)
      stat = ::Process::waitpid pid
      if raise_on_error and not stat.success?
        raise %{
From the remote_table gem...

Command failed:
#{cmd}

Exit code:
#{stat.exitstatus}
}
      end
    end
  end
end
