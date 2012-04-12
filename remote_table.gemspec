# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "remote_table/version"

Gem::Specification.new do |s|
  s.name        = "remote_table"
  s.version     = RemoteTable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere", "Andy Rossmeissl"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/remote_table"
  s.summary     = "Open local or remote XLSX, XLS, ODS, CSV and fixed-width files."
  s.description = %q{Gives you a standard way to parse various formats and treat them as an array of hashes.}

  s.rubyforge_project = "remotetable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency 'activesupport', '>=2.3.4'
  s.add_runtime_dependency 'roo', '>=1.9'
  s.add_runtime_dependency 'fixed_width-multibyte', '>=0.2.3'
  s.add_runtime_dependency 'i18n' # activesupport?
  s.add_runtime_dependency 'unix_utils'
  s.add_runtime_dependency 'fastercsv', '>=1.5.0'
  s.add_runtime_dependency 'hash_digest'

  s.add_development_dependency 'errata', '>=0.2.0'
  s.add_development_dependency 'test-unit'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'rake'
end
