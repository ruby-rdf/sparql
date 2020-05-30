$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'sparql/client'

include SPARQL::Algebra

describe SPARQL::Algebra::Query do
  EX = RDF::EX = RDF::Vocabulary.new('http://example.org/') unless const_defined?(:EX)

  context "describe" do
    {
      uri: [
        %q{
          <http://example/subject> a <http://example/type> .
          <http://example/subject2> a <http://example/anothertype> .
        },
        %q{
          <http://example/subject> a <http://example/type> .
        },
        %q{
          (describe (<http://example/subject>) (bgp))
        },
      ],
      foaf: [
        %q{
          @prefix foaf:   <http://xmlns.com/foaf/0.1/> .
          @prefix vcard:  <http://www.w3.org/2001/vcard-rdf/3.0> .
          @prefix exOrg:  <http://org.example.com/employees#> .
          @prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          @prefix owl:    <http://www.w3.org/2002/07/owl#> .

          _:a     exOrg:employeeId    "1234" ;
                  foaf:mbox_sha1sum   "ABCD1234" ;
                  vcard:N
                   [ vcard:Family       "Smith" ;
                     vcard:Given        "John"  ] .

          foaf:mbox_sha1sum  rdf:type  owl:InverseFunctionalProperty .
        },
        %q{
          @prefix foaf:   <http://xmlns.com/foaf/0.1/> .
          @prefix vcard:  <http://www.w3.org/2001/vcard-rdf/3.0> .
          @prefix exOrg:  <http://org.example.com/employees#> .
          @prefix rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
          @prefix owl:    <http://www.w3.org/2002/07/owl#> .

          _:a     exOrg:employeeId    "1234" ;
                  foaf:mbox_sha1sum   "ABCD1234" ;
                  vcard:N
                   [ vcard:Family       "Smith" ;
                     vcard:Given        "John"  ] .
        },
        %q{
          (prefix ((exOrg: <http://org.example.com/employees#>))
            (describe (?x)
              (bgp (triple ?x exOrg:employeeId "1234"))))
        }
      ]
    }.each do |example, (source, result, query)|
      it "describes #{example}" do
        graph_r = RDF::Graph.new << RDF::Turtle::Reader.new(result)

        expect(
          sparql_query(
            form: :describe, sse: true,
            graphs: {default: {data: source, format: :ttl}},
            query: query)
        ).to be_isomorphic graph_r
      end

      it "describes #{example} (with optimization)" do
        graph_r = RDF::Graph.new << RDF::Turtle::Reader.new(result)

        expect(
          sparql_query(
            form: :describe, sse: true, optimize: true,
            graphs: {default: {data: source, format: :ttl}},
            query: query)
        ).to be_isomorphic graph_r
      end
    end
  end
end
