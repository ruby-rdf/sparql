#!/usr/bin/env ruby
$:.unshift(File.expand_path("../../lib", __FILE__))

require "bundler/setup"
require 'benchmark'
require 'sparql'
require 'rdf/turtle'
graph = RDF::Graph.load("etc/doap.ttl")
query = nil

Benchmark.bmbm do |bench|
  bench.report("sparql parse") do
    100_000.times do
      query = SPARQL.parse %(
        PREFIX foaf: <>
        SELECT ?name
        WHERE {
          [foaf:name ?name]
        }
      )
    end
  end
end

Benchmark.bmbm do |bench|
  bench.report("sparql execute") do
    100_000.times do
      graph.query(query) {}
    end
  end
end
