#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))
require 'rubygems'
require 'yard'
require 'rspec/core/rake_task'

task default: :spec
task specs: :spec

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
    require 'suite_helper'
    
    puts "load 1.0 tests"
    SPARQL::Spec.sparql_11_tests(true)
    puts "load 1.0 syntax tests"
    SPARQL::Spec.sparql_11_syntax_tests(true)
    puts "load 1.1 tests"
    SPARQL::Spec.sparql_11_tests(true)
  end
end

namespace :doc do
  YARD::Rake::YardocTask.new

  desc "Generate HTML report specs"
  RSpec::Core::RakeTask.new("spec") do |spec|
    spec.rspec_opts = ["--format", "html", "-o", "doc/spec.html"]
  end
end

desc "Create concatenated test manifests"
file "etc/manifest-cache.nt" do
  require 'rdf'
  require 'rdf/turtle'
  require 'rdf/ntriples'
  graph = RDF::Graph.new do |g|
    {
      "http://w3c.github.io/rdf-tests/sparql/" => "../w3c-rdf-tests/sparql/",
      "https://w3c.github.io/sparql-dev/tests/" => "../w3c-sparql-dev/tests/"
    }.each do |base, path|
      Dir.glob("#{path}**/manifest.ttl").each do |man|
        puts "load #{man}"
        g.load(man, unique_bnodes: true, base_uri: man.sub(path, base))
      end
    end
  end
  puts "write"
  RDF::NTriples::Writer.open("etc/manifest-cache.nt", unique_bnodes: true, validate: false) {|w| w << graph}
end

desc 'Create versions of ebnf files in etc'
task etc: %w{etc/sparql12.sxp etc/sparql12.html etc/sparql12.peg.sxp}

desc 'Build first, follow and branch tables'
task meta: "lib/sparql/grammar/meta.rb"

file "lib/sparql/grammar/meta.rb" => "etc/sparql12.bnf" do |t|
  sh %{
    ebnf --peg --format rb \
      --mod-name SPARQL::Grammar::Meta \
      --output lib/sparql/grammar/meta.rb \
      etc/sparql12.bnf
  }
end

file "etc/sparql12.sxp" => "etc/sparql12.bnf" do |t|
  sh %{
    ebnf --bnf --format sxp \
      --output etc/sparql12.sxp \
      etc/sparql12.bnf
  }
end

file "etc/sparql12.peg.sxp" => "etc/sparql12.bnf" do |t|
  sh %{
    ebnf --peg --format sxp \
      --output etc/sparql12.peg.sxp \
      etc/sparql12.bnf
  }
end

file "etc/sparql12.html" => "etc/sparql12.bnf" do |t|
  sh %{
    ebnf --format html \
      --output etc/sparql12.html \
      --renumber \
      etc/sparql12.bnf
  }
end

sse_files = Dir.glob("./spec/dawg/**/*.rq").map do |f|
  f.sub(".rq", ".sse")
end

ssu_files = Dir.glob("./spec/dawg/**/*.ru").map do |f|
  f.sub(".ru", ".sse")
end

desc "Build SSE versions of test '.rq' and '.ru' files using Jena ARQ"
task sse: sse_files + ssu_files

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
