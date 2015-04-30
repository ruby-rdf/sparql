$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'rdf/trig'

include SPARQL::Algebra

describe SPARQL::Algebra::Update do
  EX = RDF::EX = RDF::Vocabulary.new('http://example.org/') unless const_defined?(:EX)

  let(:repo) {
    RDF::Repository.new << RDF::TriG::Reader.new(%(
      @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
      @prefix :      <http://example.org/> .

      :john a foaf:Person .
      :john foaf:givenName "John" .
      :john foaf:mbox  <mailto:johnny@example.org> .
      :g1 {
        :jane a foaf:Person .
        :jane foaf:givenName "Jane" .
        :jane foaf:mbox  <mailto:jane@example.org> .
      }
      :g2 {
        :jill a foaf:Person .
        :jill foaf:givenName "Jill" .
        :jill foaf:mbox  <mailto:jill@example.org> .
      }
    ))
  }
  describe "update" do
    it "raises IOError if queryable is not mutable" do
      expect(repo).to receive(:writable?).and_return(false)
      query = SPARQL::Algebra::Expression.parse(%q((update)))
      expect {query.execute(repo)}.to raise_error(IOError, "queryable is not mutable")
    end
  end

  context "sse" do
    {
      "add default to default" => {
        query: %q{(update (add default default))},
        expected: %(
          @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
          @prefix :      <http://example.org/> .

          :john a foaf:Person .
          :john foaf:givenName "John" .
          :john foaf:mbox  <mailto:johnny@example.org> .
          :g1 {
            :jane a foaf:Person .
            :jane foaf:givenName "Jane" .
            :jane foaf:mbox  <mailto:jane@example.org> .
          }
          :g2 {
            :jill a foaf:Person .
            :jill foaf:givenName "Jill" .
            :jill foaf:mbox  <mailto:jill@example.org> .
          }
        )
      },
      "add non-exist to default raises error" => {
        query: %q{(update (add <http://not-here> default))},
        error: "add operation source does not exist"
      },
      "add default to nothing raises error" => {
        query: %q{(update (add default))},
        error: "add from must be IRI or :default"
      },
      "add default to <http://example.org/g3>" => {
        query: %q{(update (add default <http://example.org/g3>))},
        expected: %(
          @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
          @prefix :      <http://example.org/> .

          :john a foaf:Person .
          :john foaf:givenName "John" .
          :john foaf:mbox  <mailto:johnny@example.org> .
          :g1 {
            :jane a foaf:Person .
            :jane foaf:givenName "Jane" .
            :jane foaf:mbox  <mailto:jane@example.org> .
          }
          :g2 {
            :jill a foaf:Person .
            :jill foaf:givenName "Jill" .
            :jill foaf:mbox  <mailto:jill@example.org> .
          }
          :g3 {
            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .
          }
        )
      },
      "add <http://example.org/g2> to <http://example.org/g3>" => {
        query: %q{(update (add <http://example.org/g2> <http://example.org/g3>))},
        expected: %(
          @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
          @prefix :      <http://example.org/> .

          :john a foaf:Person .
          :john foaf:givenName "John" .
          :john foaf:mbox  <mailto:johnny@example.org> .
          :g1 {
            :jane a foaf:Person .
            :jane foaf:givenName "Jane" .
            :jane foaf:mbox  <mailto:jane@example.org> .
          }
          :g2 {
            :jill a foaf:Person .
            :jill foaf:givenName "Jill" .
            :jill foaf:mbox  <mailto:jill@example.org> .
          }
          :g3 {
            :jill a foaf:Person .
            :jill foaf:givenName "Jill" .
            :jill foaf:mbox  <mailto:jill@example.org> .
          }
        )
      },
      "add <http://example.org/g1> to <http://example.org/g2>" => {
        query: %q{(update (add <http://example.org/g1> <http://example.org/g2>))},
        expected: %(
          @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
          @prefix :      <http://example.org/> .

          :john a foaf:Person .
          :john foaf:givenName "John" .
          :john foaf:mbox  <mailto:johnny@example.org> .
          :g1 {
            :jane a foaf:Person .
            :jane foaf:givenName "Jane" .
            :jane foaf:mbox  <mailto:jane@example.org> .
          }
          :g2 {
            :jill a foaf:Person .
            :jill foaf:givenName "Jill" .
            :jill foaf:mbox  <mailto:jill@example.org> .
            :jane a foaf:Person .
            :jane foaf:givenName "Jane" .
            :jane foaf:mbox  <mailto:jane@example.org> .
          }
        )
      },
      "add <http://example.org/g2> to default" => {
        query: %q{(update (add <http://example.org/g2> default))},
        expected: %(
          @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
          @prefix :      <http://example.org/> .

          :john a foaf:Person .
          :john foaf:givenName "John" .
          :john foaf:mbox  <mailto:johnny@example.org> .

          :jill a foaf:Person .
          :jill foaf:givenName "Jill" .
          :jill foaf:mbox  <mailto:jill@example.org> .

          :g1 {
            :jane a foaf:Person .
            :jane foaf:givenName "Jane" .
            :jane foaf:mbox  <mailto:jane@example.org> .
          }
          :g2 {
            :jill a foaf:Person .
            :jill foaf:givenName "Jill" .
            :jill foaf:mbox  <mailto:jill@example.org> .
          }
        )
      },
    }.each do |name, opts|
      it name do
        if opts[:error]
          expect {sparql_query({sse: true, graphs: repo}.merge(opts))}.to raise_error(opts[:error])
        else
          expected = RDF::Repository.new << RDF::TriG::Reader.new(opts[:expected])
          actual = sparql_query({sse: true, graphs: repo}.merge(opts))
          expect(actual).to describe_solutions(expected, nil)
        end
      end
    end
  end
end
