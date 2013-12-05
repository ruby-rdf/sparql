$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

# Misclaneous test cases, based on observed or reported problems
describe SPARQL::Grammar do
  describe "misclaneous" do
    {
      "rdfa 0085" => {
        :graphs => { :default => { :format => :ttl, :data => %q(
            <http://www.example.org/#somebody> <http://xmlns.com/foaf/0.1/knows> _:a .
            _:a <http://xmlns.com/foaf/0.1/knows> <http://www.ivan-herman.org/Ivan_Herman> .
            _:a <http://xmlns.com/foaf/0.1/knows> <http://www.w3.org/People/Berners-Lee/card#i> .
            _:a <http://xmlns.com/foaf/0.1/knows> <http://danbri.org/foaf.rdf#danbri> .
          )
        }},
        :query => %q(
          ASK WHERE {
              <http://www.example.org/#somebody> <http://xmlns.com/foaf/0.1/knows> _:a .
            _:a <http://xmlns.com/foaf/0.1/knows> <http://www.ivan-herman.org/Ivan_Herman> ,
              <http://www.w3.org/People/Berners-Lee/card#i> ,
              <http://danbri.org/foaf.rdf#danbri> .
          }
        )
      }
    }.each do |test, options|
      it "returns true for #{test}" do
        result = sparql_query(options.merge(:repository => "sparql-spec", :form => :ask, :to_hash => false))
        expect(result).to eq RDF::Literal::TRUE
      end
    end
  end
end
