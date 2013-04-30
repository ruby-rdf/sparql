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

  context "ask" do
    it "passes data-r2/as/ask-1" do
      sparql_query(
        :form => :ask,
        :graphs => {
          :default => {
            :data => %q{
              @prefix :   <http://example/> .
              @prefix xsd:        <http://www.w3.org/2001/XMLSchema#> .

              :x :p "1"^^xsd:integer .
              :x :p "2"^^xsd:integer .
              :x :p "3"^^xsd:integer .

              :y :p :a .
              :a :q :r .
            },
            :format => :ttl
          }
        },
        :query => %q{
          (prefix ((: <http://example/>))
          (ask
            (bgp (triple :x :p 1))))
        },
        :sse => true
      ).should == RDF::Literal::TRUE
    end
  end
end
