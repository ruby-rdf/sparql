#!/usr/bin/env ruby
$:.unshift(File.expand_path("../../lib", __FILE__))

require "bundler/setup"
require 'ruby-prof'
require 'sparql'
require 'rdf/turtle'
require 'fileutils'
graph = RDF::Graph.new
%w(manifest rdf.rb-earl).each {|f| graph.load("./earl-data/#{f}.ttl")}

query = SPARQL.parse %(
  PREFIX dc: <http://purl.org/dc/terms/>
  PREFIX mf: <http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#>
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>

  SELECT ?lh ?uri ?type ?title ?description ?testAction ?testResult ?manUri ?manTitle ?manDescription
  WHERE {
    ?uri a ?type;
      mf:name ?title;
      mf:action ?testAction .
    OPTIONAL { ?uri rdfs:comment ?description . }
    OPTIONAL { ?uri mf:result ?testResult . }
    OPTIONAL {
      ?manUri a mf:Manifest; mf:entries ?lh .
      ?lh rdf:first ?uri .
      OPTIONAL { ?manUri mf:name ?manTitle . }
      OPTIONAL { ?manUri rdfs:comment ?manDescription . }
    }
  }
).freeze

#class MF < RDF::Vocabulary("http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#")
#end
#
#query = RDF::Query.new do
#  pattern [:uri, RDF.type, :type]
#  pattern [:uri, MF.name, :title]
#  pattern [:uri, MF.action, :testAction]
#  pattern [:uri, RDF::RDFS.comment, :description], optional: true
#  pattern [:uri, MF.result, :testResult], optional: true
#  pattern [:manUri, RDF.type, MF.Manifest], optional: true
#  pattern [:manUri, MF.entries, :lh], optional: true
#  pattern [:lh, RDF.first, :uri], optional: true
#  pattern [:manUri, MF.name, :manTitle], optional: true
#  pattern [:manUri, RDF::RDFS.comment, :manDescription], optional: true
#end

output_dir = File.expand_path("../../doc/profiles/#{File.basename __FILE__, ".rb"}", __FILE__)
FileUtils.mkdir_p(output_dir)

result = RubyProf.profile do
  query.execute(graph) do |solution|
    solution[:uri]
  end
end

# Print a graph profile to text
printer = RubyProf::MultiPrinter.new(result)
printer.print(path: output_dir, profile: "profile")
puts "output saved in #{output_dir}"
