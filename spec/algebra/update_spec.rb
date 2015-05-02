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
      add: {
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
        "add too many operands raises error" => {
          query: %q{(update (add default <http://example.org/g1> <http://example.org/g2>))},
          error: "add expected two operands, got 3"
        },
        "add non-exist to default raises error" => {
          query: %q{(update (add <http://not-here> default))},
          error: "add operation source does not exist"
        },
        "add default to nothing raises error" => {
          query: %q{(update (add default))},
          error: "add expected two operands, got 1"
        },
        "add non-exist to default with silent" => {
          query: %q{(update (add silent <http://not-here> default))},
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
        }
      },
      copy: {
        "copy default to default" => {
          query: %q{(update (copy default default))},
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
        "copy too many operands raises error" => {
          query: %q{(update (copy default <http://example.org/g1> <http://example.org/g2>))},
          error: "copy expected two operands, got 3"
        },
        "copy non-exist to default raises error" => {
          query: %q{(update (copy <http://not-here> default))},
          error: "copy operation source does not exist"
        },
        "copy default to nothing raises error" => {
          query: %q{(update (copy default))},
          error: "copy expected two operands, got 1"
        },
        "copy non-exist to default with silent" => {
          query: %q{(update (copy silent <http://not-here> default))},
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
        "copy default to <http://example.org/g3>" => {
          query: %q{(update (copy default <http://example.org/g3>))},
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
        "copy <http://example.org/g2> to <http://example.org/g3>" => {
          query: %q{(update (copy <http://example.org/g2> <http://example.org/g3>))},
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
        "copy <http://example.org/g1> to <http://example.org/g2>" => {
          query: %q{(update (copy <http://example.org/g1> <http://example.org/g2>))},
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
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
              :jane foaf:mbox  <mailto:jane@example.org> .
            }
          )
        },
        "copy <http://example.org/g2> to default" => {
          query: %q{(update (copy <http://example.org/g2> default))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

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
        }
      },
      clear: {
        "clear default" => {
          query: %q{(update (clear default))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

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
        "clear too many operands raises error" => {
          query: %q{(update (clear <http://not-here> default))},
          error: "clear expected operand to be 'default', 'named', 'all', or an IRI"
        },
        "clear non-exist raises error" => {
          query: %q{(update (clear <http://not-here>))},
          error: "clear operation graph does not exist"
        },
        "clear nothing raises error" => {
          query: %q{(update (clear))},
          error: "clear expected operand to be 'default', 'named', 'all', or an IRI"
        },
        "clear non-exist with silent" => {
          query: %q{(update (clear silent <http://not-here>))},
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
        "clear <http://example.org/g1>" => {
          query: %q{(update (clear <http://example.org/g1>))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .

            :g2 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          )
        },
        "clear named" => {
          query: %q{(update (clear named))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .
          )
        },
        "clear all" => {
          query: %q{(update (clear all))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .
          )
        },
      },
      create: {
        "create <http://example.org/g3>" => {
          query: %q{(update (create <http://example.org/g3>))},
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
        "create too many operands raises error" => {
          query: %q{(update (create <http://not-here> <http://not-there>))},
          error: "clear expected a single IRI"
        },
        "create default raises error" => {
          query: %q{(update (create default))},
          error: "clear expected a single IRI"
        },
        "create nothing raises error" => {
          query: %q{(update (create))},
          error: "clear expected a single IRI"
        },
        "create existing raises error" => {
          query: %q{(update (create <http://example.org/g1>))},
          error: "create operation graph <http://example.org/g1> exists"
        },
        "create existing with silent" => {
          query: %q{(update (create silent <http://example.org/g1>))},
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
      },
      deleteData: {
        "delete triple from default" => {
          query: %q{
            (update
              (deleteData ((triple <http://example.org/john>
                                   <http://xmlns.com/foaf/0.1/mbox>
                                   <mailto:johnny@example.org>))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .

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
          }
        },
        "delete triple from :g1" => {
          query: %q{
            (update
              (deleteData
                ((graph <http://example.org/g1>
                  ((triple <http://example.org/jane>
                           <http://xmlns.com/foaf/0.1/mbox>
                           <mailto:jane@example.org>))))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .

            :g1 {
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
            }
            :g2 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          }
        },
        "delete triples from default and :g1" => {
          query: %q{
            (update
              (deleteData
                ((triple <http://example.org/john>
                         <http://xmlns.com/foaf/0.1/mbox>
                         <mailto:johnny@example.org>)
                 (graph <http://example.org/g1>
                  ((triple <http://example.org/jane>
                           <http://xmlns.com/foaf/0.1/mbox>
                           <mailto:jane@example.org>))))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .

            :g1 {
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
            }
            :g2 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          }
        },
      },
      deleteWhere: {
        "delete pattern from default" => {
          query: %q{
            (update
              (deleteWhere ((triple <http://example.org/john>
                                   <http://xmlns.com/foaf/0.1/mbox>
                                   ?v))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .

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
          }
        },
        "delete pattern from :g1" => {
          query: %q{
            (update
              (deleteWhere
                ((graph <http://example.org/g1>
                  ((triple <http://example.org/jane>
                           <http://xmlns.com/foaf/0.1/mbox>
                           ?v))))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .

            :g1 {
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
            }
            :g2 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          }
        },
        "delete patterns from default and :g1" => {
          query: %q{
            (update
              (deleteWhere
                ((triple <http://example.org/john>
                         <http://xmlns.com/foaf/0.1/mbox>
                         ?a)
                 (graph <http://example.org/g1>
                  ((triple <http://example.org/jane>
                           <http://xmlns.com/foaf/0.1/mbox>
                           ?b))))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .

            :g1 {
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
            }
            :g2 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          }
        },
      },
      drop: {
        "drop default" => {
          query: %q{(update (drop default))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

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
        "drop too many operands raises error" => {
          query: %q{(update (drop <http://not-here> default))},
          error: "drop expected operand to be 'default', 'named', 'all', or an IRI"
        },
        "drop non-exist raises error" => {
          query: %q{(update (drop <http://not-here>))},
          error: "drop operation graph does not exist"
        },
        "drop nothing raises error" => {
          query: %q{(update (drop))},
          error: "drop expected operand to be 'default', 'named', 'all', or an IRI"
        },
        "drop non-exist with silent" => {
          query: %q{(update (drop silent <http://not-here>))},
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
        "drop <http://example.org/g1>" => {
          query: %q{(update (drop <http://example.org/g1>))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .

            :g2 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          )
        },
        "drop named" => {
          query: %q{(update (drop named))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .
          )
        },
        "drop all" => {
          query: %q{(update (drop all))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .
          )
        },
      },
      insertData: {
        "insert triple to default" => {
          query: %q{
            (update
              (insertData ((triple <http://example.org/john>
                                   <http://xmlns.com/foaf/0.1/knows>
                                   <http://example.org/jane>))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .
            :john foaf:knows :jane .

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
          }
        },
        "insert triple to :g1" => {
          query: %q{
            (update
              (insertData
                ((graph <http://example.org/g1>
                  ((triple <http://example.org/jane>
                           <http://xmlns.com/foaf/0.1/knows>
                           <http://example.org/john>))))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .

            :g1 {
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
              :jane foaf:mbox  <mailto:jane@example.org> .
              :jane foaf:knows :john .
            }
            :g2 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          }
        },
        "insert triples to default and :g1" => {
          query: %q{
            (update
              (insertData
                ((triple <http://example.org/john>
                         <http://xmlns.com/foaf/0.1/knows>
                         <http://example.org/jane>)
                 (graph <http://example.org/g1>
                  ((triple <http://example.org/jane>
                           <http://xmlns.com/foaf/0.1/knows>
                           <http://example.org/john>))))))
          },
          expected: %{
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .
            :john foaf:knows :jane .

            :g1 {
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
              :jane foaf:mbox  <mailto:jane@example.org> .
              :jane foaf:knows :john .
            }
            :g2 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          }
        },
      },
      load: {
        # FIXME
      },
      modify: {
        
      },
      move: {
        "move default to default" => {
          query: %q{(update (move default default))},
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
        "move too many operands raises error" => {
          query: %q{(update (move default <http://example.org/g1> <http://example.org/g2>))},
          error: "move expected two operands, got 3"
        },
        "move non-exist to default raises error" => {
          query: %q{(update (move <http://not-here> default))},
          error: "move operation source does not exist"
        },
        "move default to nothing raises error" => {
          query: %q{(update (move default))},
          error: "move expected two operands, got 1"
        },
        "move non-exist to default with silent" => {
          query: %q{(update (move silent <http://not-here> default))},
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
        "move default to <http://example.org/g3>" => {
          query: %q{(update (move default <http://example.org/g3>))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

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
        "move <http://example.org/g2> to <http://example.org/g3>" => {
          query: %q{(update (move <http://example.org/g2> <http://example.org/g3>))},
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
            :g3 {
              :jill a foaf:Person .
              :jill foaf:givenName "Jill" .
              :jill foaf:mbox  <mailto:jill@example.org> .
            }
          )
        },
        "move <http://example.org/g1> to <http://example.org/g2>" => {
          query: %q{(update (move <http://example.org/g1> <http://example.org/g2>))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :john a foaf:Person .
            :john foaf:givenName "John" .
            :john foaf:mbox  <mailto:johnny@example.org> .
            :g2 {
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
              :jane foaf:mbox  <mailto:jane@example.org> .
            }
          )
        },
        "move <http://example.org/g2> to default" => {
          query: %q{(update (move <http://example.org/g2> default))},
          expected: %(
            @prefix foaf:  <http://xmlns.com/foaf/0.1/> .
            @prefix :      <http://example.org/> .

            :jill a foaf:Person .
            :jill foaf:givenName "Jill" .
            :jill foaf:mbox  <mailto:jill@example.org> .

            :g1 {
              :jane a foaf:Person .
              :jane foaf:givenName "Jane" .
              :jane foaf:mbox  <mailto:jane@example.org> .
            }
          )
        }
      },
    }.each do |name, tests|
      describe name do
        tests.each do |tname, opts|
          it tname do
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
  end
end
