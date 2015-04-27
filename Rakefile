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
    puts "load 1.1 tests"
    SPARQL::Spec.sparql1_1_tests(true)
  end
end

namespace :doc do
  YARD::Rake::YardocTask.new

  desc "Generate HTML report specs"
  RSpec::Core::RakeTask.new("spec") do |spec|
    spec.rspec_opts = ["--format", "html", "-o", "doc/spec.html"]
  end
end

desc 'Create versions of ebnf files in etc'
task :etc => %w{etc/sparql11.sxp etc/sparql11.ll1.sxp etc/update.ll1.sxp}

desc 'Build first, follow and branch tables'
task :meta => ["lib/sparql/grammar/meta.rb", "lib/sparql/update/meta.rb"]

file "lib/sparql/grammar/meta.rb" => "etc/sparql11.bnf" do |t|
  sh %{
    ebnf --ll1 QueryUnit --ll1 UpdateUnit --format rb \
      --mod-name SPARQL::Grammar::Meta \
      --output lib/sparql/grammar/meta.rb \
      etc/sparql11.bnf
  }
end

file "etc/sparql11.ll1.sxp" => "etc/sparql11.bnf" do |t|
  sh %{
    ebnf --ll1 QueryUnit --ll1 UpdateUnit --format sxp \
      --output etc/sparql11.ll1.sxp \
      etc/sparql11.bnf
  }
end

file "etc/sparql11.sxp" => "etc/sparql11.bnf" do |t|
  sh %{
    ebnf --bnf --format sxp \
      --output etc/sparql11.sxp \
      etc/sparql11.bnf
  }
end

file "etc/sparql11.html" => "etc/sparql11.bnf" do |t|
  sh %{
    ebnf --format html \
      --output etc/sparql11.html \
      etc/sparql11.bnf
  }
end

sse_files = Dir.glob("./spec/dawg/**/*.rq").map do |f|
  f.sub(".rq", ".sse")
end

ssu_files = Dir.glob("./spec/dawg/**/*.ru").map do |f|
  f.sub(".ru", ".sse")
end

desc "Build SSE versions of test '.rq' and '.ru' files using Jena ARQ"
task :sse => sse_files + ssu_files

# Rule to create SSE files from .rq
rule ".sse" => %w{.rq} do |t|
  puts "build #{t.name}"
  sse = `qparse --print op --file #{t.source} 2> /dev/null` rescue nil
  if $? == 0
    File.open(t.name, "w") {|f| f.write(sse)}
  else
    puts "skipped #{t.source}"
  end
end

# Rule to create SSE files from .ru
rule ".sse" => %w{.ru} do |t|
  puts "build #{t.name}"
  sse = `uparse --print op --file #{t.source} 2> /dev/null` rescue nil
  if $? == 0
    File.open(t.name, "w") {|f| f.write(sse)}
  else
    puts "skipped #{t.source}"
  end
end
