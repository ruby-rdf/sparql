#!/usr/bin/env ruby
$:.unshift(File.expand_path("../../lib", __FILE__))

require "bundler/setup"
require 'ruby-prof'
require 'sparql'
require 'rdf/turtle'
require 'fileutils'
graph = RDF::Graph.load("etc/doap.ttl")
query = nil

output_dir = File.expand_path("../../doc/profiles/#{File.basename __FILE__, ".rb"}", __FILE__)
FileUtils.mkdir_p(output_dir)

result = RubyProf.profile do
  1000.times do
    query = SPARQL.parse %(
      PREFIX foaf: <>
      SELECT ?name
      WHERE {
        [foaf:name ?name]
      }
    )
  end
end

# Print a graph profile to text
printer = RubyProf::MultiPrinter.new(result)
printer.print(path: output_dir, profile: "profile")
puts "output saved in #{output_dir}"
