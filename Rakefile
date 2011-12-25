require 'rubygems'
require 'rake'
require 'rdoc/task'
require 'rspec/core/rake_task'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "king_views"
    gem.summary = %Q{Ultraclean haml views with list and forms helpers for rails }
    gem.description = %Q{Clean up your Forms using king_form for dl or labeled forms. Use king_list for an easy markup of tables in your lists and dl-enabled listings in your detail views. }
    gem.email = "gl@salesking.eu"
    gem.homepage = "http://github.com/salesking/king_views"
    gem.authors = ["Georg Leciejewski"]
    #gem.add_development_dependency "rspec", ">= 0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

desc 'Generate king_views documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'KingViews'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('king_form/lib/**/*.rb')
  rdoc.rdoc_files.include('king_format/lib/**/*.rb')
  rdoc.rdoc_files.include('king_list/lib/**/*.rb')
end
