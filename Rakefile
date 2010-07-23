require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the acts_as_extjs plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the acts_as_extjs plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsExtjs'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "the-perfect-gem"
    gemspec.summary = "One line summary of your gem"
    gemspec.description = "A different and possibly longer explanation of"
    gemspec.email = "josh@technicalpickles.com"
    gemspec.homepage = "http://github.com/technicalpickles/the-perfect-gem"
    gemspec.authors = ["Josh Nichols"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
