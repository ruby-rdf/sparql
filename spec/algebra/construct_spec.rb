$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'sparql/client'

include SPARQL::Algebra

describe SPARQL::Algebra::Query do
  EX = RDF::EX = RDF::Vocabulary.new('http://example.org/') unless const_defined?(:EX)

  let(:logger) {RDF::Spec.logger.tap {|l| l.level = Logger::INFO}}

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
      "reused bnode label" => [
        %q(),
        %q(
          @prefix ex: <http://example.com/> .
          ex:s ex:p1 [ex:p2 ex:o1] .
        ),
        %q{(prefix
           ((ex: <http://example.com/>))
           (construct ((triple ex:s ex:p1 _:b1) (triple _:b1 ex:p2 ex:o1)) (bgp)))},
      ]
    }.each do |example, (source, result, query)|
      it "constructs #{example}" do
        logger.info "Source:\n#{source}"
        logger.info "Result:\n#{result}"
        logger.info "Query:\n#{query}"
        graph_r = RDF::Graph.new << RDF::Turtle::Reader.new(result)

        expect(
          sparql_query(
            form: :construct, sse: true,
            graphs: {default: {data: source, format: :ttl}},
            query: query)
        ).to be_isomorphic(graph_r), logger.to_s
      end

      it "constructs #{example} (with optimization)" do
        logger.info "Source:\n#{source}"
        logger.info "Result:\n#{result}"
        logger.info "Query:\n#{query}"
        logger.info "Optimized:\n#{SXP::Generator.string(SPARQL::Algebra.parse(query, optimize: true).to_sxp_bin)}"
        graph_r = RDF::Graph.new << RDF::Turtle::Reader.new(result)

        expect(
          sparql_query(
            form: :construct, sse: true, optimize: true,
            graphs: {default: {data: source, format: :ttl}},
            query: query)
        ).to be_isomorphic(graph_r), logger.to_s
      end
    end
  end
end
