#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", 'lib')))
require 'rubygems'
require "bundler/setup"
require 'linkeddata'

query = SPARQL.parse %{
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
  ASK WHERE {
    [ rdf:value "2012-03-18"^^xsd:date ] .
  }
}

repo = RDF::Graph.new << RDF::Turtle::Reader.new(%{
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
  <http://rdfa.info/test-suite/test-cases/rdfa1.1/html5/0272.html> rdf:value "2012-03-18"^^xsd:date .
})

begin
  results = query.execute(repo, :debug => true)
  puts "Returned #{results.inspect}"
rescue Exception => e
  puts "Raised error: #{e.inspect}"
end
