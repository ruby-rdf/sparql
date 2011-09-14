#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))
require 'rubygems'
require 'yard'
require 'rspec/core/rake_task'

task :default => :spec
task :specs => :spec

namespace :gem do
  desc "Build the sparql-#{File.read('VERSION').chomp}.gem file"
  task :build do
    sh "gem build sparql.gemspec && mv sparql-#{File.read('VERSION').chomp}.gem pkg/"
  end

  desc "Release the sparql-#{File.read('VERSION').chomp}.gem file"
  task :release do
    sh "gem push pkg/sparql-#{File.read('VERSION').chomp}.gem"
  end
end

RSpec::Core::RakeTask.new(:spec)

desc "Run specs through RCov"
RSpec::Core::RakeTask.new("spec:rcov") do |spec|
  spec.rcov = true
  spec.rcov_opts =  %q[--exclude "spec"]
end

namespace :spec do
  desc "Generate test caches"
  task :prepare do
    $:.unshift(File.join(File.dirname(__FILE__), 'spec'))
    require 'dawg_helper'
    require 'fileutils'
    
    Dir.glob("spec/dawg/*.yml") { |yml| FileUtils.rm_rf(yml)}

    puts "load 1.0 tests"
    SPARQL::Spec.sparql1_0_tests(true)
    puts "load 1.0 syntax tests"
    SPARQL::Spec.sparql1_0_syntax_tests(true)
    #puts "load 1.1 tests"
    #SPARQL::Spec.sparql1_1_tests(true)
  end
end

namespace :doc do
  YARD::Rake::YardocTask.new

  desc "Generate HTML report specs"
  RSpec::Core::RakeTask.new("spec") do |spec|
    spec.rspec_opts = ["--format", "html", "-o", "doc/spec.html"]
  end
end
