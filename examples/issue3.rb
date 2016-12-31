#!/usr/bin/env ruby

require 'rdf'
require 'sparql'

class TestRepo < RDF::Repository
  def query(pattern, &block)
    #puts "received pattern #{pattern.inspect}"

    statements = []
    if pattern[:predicate].path == '/attribute_types/first_name'
      statements << RDF::Statement.new(
        :subject   => RDF::URI.new('http://localhost/people/1'),
        predicate: RDF::URI.new('http://localhost/attribute_types/first_name'),
        :object    => RDF::Literal.new('joe'))
    elsif pattern[:predicate].path == '/attribute_types/last_name'
      statements << RDF::Statement.new(
        :subject   => RDF::URI.new('http://localhost/people/1'),
        predicate: RDF::URI.new('http://localhost/attribute_types/last_name'),
        :object    => RDF::Literal.new('smith'))
    elsif pattern[:predicate].path == '/attribute_types/middle_name'
      statements << RDF::Statement.new(
        :subject   => RDF::URI.new('http://localhost/people/2'),
        predicate: RDF::URI.new('http://localhost/attribute_types/middle_name'),
        :object    => RDF::Literal.new('blah'))

      statements << RDF::Statement.new(
        :subject   => RDF::URI.new('http://localhost/people/1'),
        predicate: RDF::URI.new('http://localhost/attribute_types/middle_name'),
        :object    => RDF::Literal.new('blah'))

    end

    statements.each(&block)
  end
end


query = %q(
PREFIX a: <http://localhost/attribute_types/>
  SELECT ?entity
  WHERE {
    ?entity a:first_name 'joe' .
    ?entity a:last_name 'smith' .
    OPTIONAL {
      ?entity a:middle_name 'blah'
    }
  }
)

rep = TestRepo.new(base_url: 'http://localhost')
sse = SPARQL.parse(query)
puts sse.to_sse

solutions = sse.execute(rep, debug: true)

solutions.each_solution do |s|
  puts s.to_h
end
