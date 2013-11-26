# -*- encoding: utf-8 -*-
require File.expand_path("../lib/remote_table/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "remote_table"
  s.version     = RemoteTable::VERSION
  s.authors     = ["Seamus Abshere", "Andy Rossmeissl"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = "https://github.com/seamusabshere/remote_table"
  s.summary     = %{Open local or remote XLSX, XLS, ODS, CSV (comma separated), TSV (tab separated), other delimited, fixed-width files, and Google Docs. Returns an enumerator of Arrays or Hashes, depending on whether there are headers.}
  s.description = %{Open local or remote XLSX, XLS, ODS, CSV (comma separated), TSV (tab separated), other delimited, fixed-width files, and Google Docs. Returns an enumerator of Arrays or Hashes, depending on whether there are headers.}

  s.rubyforge_project = "remotetable"

  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'activesupport', '>=2.3.4'
  s.add_runtime_dependency 'roo', '>= 1.11'
  s.add_runtime_dependency 'fixed_width-multibyte', '>=0.2.3'
  s.add_runtime_dependency 'i18n' # activesupport?
  s.add_runtime_dependency 'unix_utils', '>=0.0.8'
  s.add_runtime_dependency 'fastercsv', '>=1.5.0'
  s.add_runtime_dependency 'hash_digest'
  s.add_runtime_dependency 'rubyzip2'

  s.add_development_dependency 'errata', '>=0.2.0'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-rescue'
  s.add_development_dependency 'pry-stack_explorer'
end
