require 'singleton'
require 'escape'
require 'fileutils'
require 'posix/spawn'

class RemoteTable
  class Executor
    include ::Singleton
    # we should really be piping things i think
    def bang(path, cmd)
      srand # in case this was forked by resque
      tmp_path = "#{path}.bang.#{rand}"
      backtick_with_reporting "cat #{::Escape.shell_single_word path} | #{cmd} > #{::Escape.shell_single_word tmp_path}"
      ::FileUtils.mv tmp_path, path
    end

    def backtick_with_reporting(cmd, raise_on_error = false)
      cmd = cmd.gsub /\n/m, ' '
      if ::ENV['REMOTE_TABLE_DEBUG'] and ::ENV['REMOTE_TABLE_DEBUG'].include? 'backtick'
        $stderr.puts "[remote_table] Executing #{cmd}"
      end
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
