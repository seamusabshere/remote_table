require 'fileutils'
require 'posix/spawn'
require 'tmpdir'

class RemoteTable
  class SpawnError < ::RuntimeError; end
  
  module Utils
    def self.tmp_path(ancestor)
      basename = ::File.basename(ancestor).sub(/remote_table-[0-9]+-/, '')
      ::Kernel.srand
      ::File.join ::Dir.tmpdir, "remote_table-#{::Kernel.rand(1e11)}-#{basename}"
    end

    def self.spawn(*argv)
      options = argv.extract_options!
      if options[:in] or options[:out]
        # capture these now because posix/spawn is known to bork them
        in_out = options.slice(:in, :out).map { |k, v| ":#{k} => #{v.path}" }.join(', ')
        # --
        pid = ::POSIX::Spawn.spawn *argv, options
        ::Process.waitpid pid
        raise SpawnError, "Spawn #{argv.join(' ')} (#{in_out}) failed with exit status #{$?.exitstatus}" unless $?.success?
      else
        child = ::POSIX::Spawn::Child.new *argv
        raise SpawnError, "Spawn #{argv.join(' ')}) failed with #{child.err}" unless child.success?
      end
      nil
    end

    def self.in_place(*args)
      options = args.extract_options!
      input = args.shift
      argv = args
      output = tmp_path input
      ::File.open(input, 'r') do |f0|
        ::File.open(output, 'wb') do |f1|
          spawn *argv, :in => f0, :out => f1
        end
      end
      ::FileUtils.mv output, input
      nil
    rescue SpawnError => e
      if options[:ignore_error]
        $stderr.puts "[remote_table] #{e.inspect} (ignoring error...)"
        ::FileUtils.mv output, input
      else
        raise e
      end
    end

    def self.download(uri, form_data = nil)
      output = tmp_path uri.path

      if uri.scheme == 'file'
        $stdout.puts "[remote_table] Getting #{uri.path} from the local file system" if ::ENV['REMOTE_TABLE_VERBOSE'] == 'true'
        ::FileUtils.cp uri.path, output
        return output
      end
      
      argv = [ 'curl', '--location', '--show-error', '--silent', '--compressed', '--header', 'Expect: ' ]
      if form_data
        argv += [ '--data', form_data ]
      end
      argv += [ uri.to_s, '--output', output ]

      # sabshere 7/20/11 make web requests move more slowly so you don't get accused of DOS
      if ::ENV.has_key?('REMOTE_TABLE_DELAY_BETWEEN_REQUESTS')
        ::Kernel.sleep ::ENV['REMOTE_TABLE_DELAY_BETWEEN_REQUESTS'].to_i
      end

      $stdout.puts "[remote_table] Downloading #{uri.to_s}" if ::ENV['REMOTE_TABLE_VERBOSE'] == 'true'
      spawn *argv
      output
    end
    
    def self.decompress(input, compression)
      case compression
      when :zip, :exe
        Utils.unzip input
      when :bz2
        Utils.bunzip2 input
      when :gz
        Utils.gunzip input
      else
        raise ::ArgumentError, "Unrecognized compression #{compression}"
      end
    end
    
    def self.unpack(input, packing)
      case packing
      when :tar
        Utils.untar input
      else
        raise ::ArgumentError, "Unrecognized packing #{packing}"
      end
    end
    
    def self.pick(input, options = {})
      options = options.symbolize_keys
      if (options[:filename] or options[:glob]) and not ::File.directory?(input)
        raise ::RuntimeError, "Expecting #{input} to be a directory"
      end
      if filename = options[:filename]
        src = ::File.join input, filename
        raise(::RuntimeError, "Expecting #{src} to be a file") unless ::File.file?(src)
        output = tmp_path src
        ::FileUtils.mv src, output
        ::FileUtils.rm_rf input if ::File.dirname(input).start_with?(::Dir.tmpdir)
      elsif glob = options[:glob]
        src = ::Dir[input+glob].first
        raise(::RuntimeError, "Expecting #{glob} to find a file in #{input}") unless src and ::File.file?(src)
        output = tmp_path src
        ::FileUtils.mv src, output
        ::FileUtils.rm_rf input if ::File.dirname(input).start_with?(::Dir.tmpdir)
      else
        output = tmp_path input
        ::FileUtils.mv input, output
      end
      output
    end

    def self.gunzip(input)
      output = tmp_path input
      ::File.open(output, 'wb') do |f|
        spawn 'gunzip', '--stdout', input, :out => f
      end
      ::FileUtils.rm_f input
      output
    end

    def self.bunzip2(input)
      output = tmp_path input
      ::File.open(output, 'wb') do |f|
        spawn 'bunzip2', '--stdout', input, :out => f
      end
      ::FileUtils.rm_f input
      output
    end

    def self.untar(input)
      dest_dir = tmp_path input
      ::FileUtils.mkdir dest_dir
      spawn 'tar', '-xf', input, '-C', dest_dir
      ::FileUtils.rm_f input
      dest_dir
    end

    def self.unzip(input)
      dest_dir = tmp_path input
      ::FileUtils.mkdir dest_dir
      spawn 'unzip', '-qq', '-n', input, '-d', dest_dir
      ::FileUtils.rm_f input
      dest_dir
    end
  end
end
