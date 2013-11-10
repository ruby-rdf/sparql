$:.unshift ".."
require 'spec_helper'
require 'algebra/algebra_helper'
require 'sparql/client'

include SPARQL::Algebra

::RSpec::Matchers.define :have_result_set do |expected|
  match do |result|
    result.map(&:to_hash).to_set.should == expected.to_set
  end
end

describe SPARQL::Algebra::Query do
  EX = RDF::EX = RDF::Vocabulary.new('http://example.org/') unless const_defined?(:EX)

  context "construct" do
    {
      "query-construct-optional" => [
        %q{
          @prefix : <http://example/> .
          @prefix xsd:        <http://www.w3.org/2001/XMLSchema#> .

          :x :p :a .
          :x :p :b .
          :x :p :c .
          :x :p "1"^^xsd:integer .

          :a :q "2"^^xsd:integer .
          :a :r "2"^^xsd:integer .

          :b :q "2"^^xsd:integer .
        },
        %q{
          @prefix :        <http://example/> .
          @prefix xsd:        <http://www.w3.org/2001/XMLSchema#> .

          :x    :p2           "2"^^xsd:integer .
        },
        %q{
          (prefix ((: <http://example/>))
            (construct ((triple ?x :p2 ?v))
              (leftjoin
                (bgp (triple ?x :p ?o))
                (bgp (triple ?o :q ?v)))))
        },
      ],
      "bound node" => [
        %q(
          @prefix ex: <http://example.com/> .
 
          [] a ex:bound .
          [] a ex:somethingElse .
        ),
        %q(
          @prefix ex: <http://example.com/> .
          [] ex:label "Should appear once" .
        ),
        %q(
          (prefix
           ((ex: <http://example.com/>))
           (construct ((triple _:b0 ex:label "Should appear once"))
            (bgp (triple ??0 a ex:bound))))
        )
      ],
      "unbound node" => [
        %q(
          @prefix ex: <http://example.com/> .
 
          [] a ex:bound .
          [] a ex:somethingElse .
        ),
        %q(
          @prefix ex: <http://example.com/> .
          [] ex:label "Should appear once" .
        ),
        %q(
          (prefix
           ((ex: <http://example.com/>))
           (construct
            ((triple _:b0 ex:label "Should appear once"))
            (filter (! (bound ?s))
              (leftjoin
                (bgp)
                (bgp (triple ?s ?p ex:not-bound)))))
          )
        )
      ],
    }.each do |example, (source, result, query)|
      it "constructs #{example}" do
        graph_r = RDF::Graph.new << RDF::Turtle::Reader.new(result)

        expect(
          sparql_query(
            :form => :describe, :sse => true,
            :graphs => {:default => {:data => source, :format => :ttl}},
            :query => query)
        ).to be_isomorphic(graph_r)
      end
    end
  end
end
