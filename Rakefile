require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "remote_table"
    gem.summary = %Q{Remotely open and parse XLS, ODS, CSV and fixed-width tables.}
    gem.description = %Q{Remotely open and parse Excel XLS, ODS, CSV and fixed-width tables.}
    gem.email = "seamus@abshere.net"
    gem.homepage = "http://github.com/seamusabshere/remote_table"
    gem.authors = ["Seamus Abshere", "Andy Rossmeissl"]
    gem.add_dependency 'roo', '1.3.11' # 1.9.3 breaks
    gem.add_dependency 'fastercsv', '>=1.5.0'
    gem.add_dependency 'activesupport', '>=2.3.4'
    gem.add_dependency 'slither', '>=0.99.3'
    gem.add_dependency 'nokogiri', '>=1.4.1'
    gem.require_path = "lib"
    gem.files.include %w(lib/remote_table) unless gem.files.empty? # seems to fail once it's in the wild
    gem.rdoc_options << '--line-numbers' << '--inline-source'
    gem.requirements << 'curl'
    gem.rubyforge_project = "remotetable"
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end




task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "remote_table #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
