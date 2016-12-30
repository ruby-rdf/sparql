#!/usr/bin/env ruby
$:.unshift(File.expand_path("../../lib", __FILE__))
require 'rubygems'
require "bundler/setup"
require 'rdf'
require 'sparql'
require 'rdf/turtle'

sse = %q(
(prefix (
  (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
  (rdfs: <http://www.w3.org/2000/01/rdf-schema#>))
  (project (?o)
    (filter (in ?o rdf:Property rdfs:Class rdf:Datatype)
      (bgp (triple ?s ?p ?o)))))
)

rep = RDF::Repository.new << RDF::Turtle::Reader.new(%{
  @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
  @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
  _:a a rdf:Property .
  _:b a rdfs:Class .
  _:c a rdf:Datatype .
})
query = SPARQL::Algebra.parse(sse)

solutions = query.execute(rep, debug: true)

solutions.each_solution do |s|
  puts s.to_h
end
