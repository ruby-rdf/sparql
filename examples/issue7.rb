#!/usr/bin/env ruby
# encoding: utf-8

require 'rdf'
require 'rdf/turtle'
require 'sparql'

graph = RDF::Graph.new 'urn:graph1'
reader = RDF::Turtle::Reader.new <<'TTL'
  @prefix ex: <urn:example#>.

  ex:Subject1 a ex:MyClass;
    ex:pred1 'Predicate 1';
    ex:pred2 'Predicate 2';
    ex:pred3 'Predicate 3';
    ex:pred4 'Predicate 4';
    ex:pred5 'Predicate 5';
    ex:pred6 'Predicate 6';
    ex:pred7 'Predicate 7'.
TTL
reader.each_statement {|stmt| graph << stmt }

solutions = ::SPARQL.execute(<<-'QRY', graph)
  PREFIX ex: <urn:example#>

  SELECT ?subj ?pred ?obj
  WHERE {
    ?subj ?pred ?obj . {
      { ?subj ex:pred1 ?obj } UNION
      { ?subj ex:pred2 ?obj } UNION
      { ?subj ex:pred3 ?obj } UNION
      { ?subj ex:pred4 ?obj } UNION
      { ?subj ex:pred5 ?obj } UNION
      { ?subj ex:pred6 ?obj } UNION
      { ?subj ex:pred7 ?obj }
    }
  }
QRY

# Print out solutions
solutions.each do |sln|
  puts sln.to_h.inspect
end

### Output
#> :subj=>urn:example#Subject1, :obj=>"Predicate 1", :pred=>urn:example#pred1
#> :subj=>urn:example#Subject1, :obj=>"Predicate 2", :pred=>urn:example#pred2
#> :subj=>urn:example#Subject1, :obj=>"Predicate 3", :pred=>urn:example#pred3

### Output expected
#> :subj=>urn:example#Subject1, :obj=>"Predicate 1", :pred=>urn:example#pred1
#> :subj=>urn:example#Subject1, :obj=>"Predicate 2", :pred=>urn:example#pred2
#> :subj=>urn:example#Subject1, :obj=>"Predicate 3", :pred=>urn:example#pred3
#> :subj=>urn:example#Subject1, :obj=>"Predicate 4", :pred=>urn:example#pred4
#> :subj=>urn:example#Subject1, :obj=>"Predicate 5", :pred=>urn:example#pred5
#> :subj=>urn:example#Subject1, :obj=>"Predicate 6", :pred=>urn:example#pred6
#> :subj=>urn:example#Subject1, :obj=>"Predicate 7", :pred=>urn:example#pred7