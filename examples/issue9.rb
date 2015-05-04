#!/usr/bin/env ruby
$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "..", 'lib')))
require 'rubygems'
require "bundler/setup"
require 'linkeddata'

rq = Kernel.open("https://raw.github.com/mwkuster/eli-budabe/master/sparql/eli_md.rq").read
repo = RDF::Repository.load("https://raw.github.com/mwkuster/eli-budabe/master/sparql/source.ttl", format: :ttl)
query = SPARQL.parse(rq)
begin
  results = query.execute(repo)
  puts results.dump(:ttl, prefixes: {
    cdm: "http://publications.europa.eu/ontology/cdm#",
    eli: "http://eurlex.europa.eu/eli#",
    xsd: "http://www.w3.org/2001/XMLSchema#",
    owl: "http://www.w3.org/2002/07/owl#"
  })
rescue Exception => e
  puts "Raised error: #{e.inspect}"
end
