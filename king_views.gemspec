# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "king_views"
  s.version = "1.2.0"
  s.authors = ["Georg Leciejewski"]
  s.description = "Clean up your Forms using king_form for dl or labeled forms. Use king_list for an easy markup of tables in your lists and dl-enabled listings in your detail views. "
  s.email = "gl@salesking.eu"
  s.license = 'MIT'

  s.files         = `git ls-files -z`.split("\x0").reject{|i| i[/^docs\//] }
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.homepage = "http://github.com/salesking/king_views"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "Ultraclean haml views with list and forms helpers for rails"


  s.add_development_dependency 'bundler', '~> 1.5'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'haml'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'json_schema_tools', '>=0.6.1'
  s.add_development_dependency 'activemodel' # required by above
  s.add_development_dependency 'rake'
  s.add_development_dependency 'tzinfo'
  s.add_development_dependency 'rails'
  s.add_development_dependency 'rspec-rails'

end