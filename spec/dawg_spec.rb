$:.unshift "."
require 'spec_helper'
require 'dawg_helper'
require 'rdf/rdfxml'

$:.unshift ".."
require 'spec_helper'
require 'dawg_helper'
require 'rdf/rdfxml'

shared_examples "DAWG" do |man, tests|
  describe man.to_s.split("/")[-2] do
    tests.each do |t|
      case t.type
      when MF.QueryEvaluationTest
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          case t.name
          when 'Basic - Term 6', 'Basic - Term 7'
            pending "Decimal format changed in SPARQL 1.1"
          when 'datatype-2 : Literals with a datatype'
            pending("datatype now returns rdf:langString for language-tagged literals")
          when /Cast to xsd:boolean/
            pending("figuring out why xsd:boolean doesn't behave according to http://www.w3.org/TR/rdf-sparql-query/#FunctionMapping")
          when /REDUCED/
            pending("REDUCED equivalent to DISTINCT")
          when /tP-/
            pending("Type promotion")
          end
          
          graphs = t.graphs
          query = t.action.query_string
          expected = t.solutions

          result = sparql_query(:graphs => graphs, :query => query, :base_uri => t.action.query_file,
                                :repository => "sparql-spec", :form => t.form, :to_hash => false)

          case t.form
          when :select
            result.should be_a(RDF::Query::Solutions)
            if man.to_s =~ /sort/
              result.should describe_ordered_solutions(expected)
            else
              result.should describe_solutions(expected)
            end
          when :create, :describe, :construct
            result.should be_a(RDF::Queryable)
            result.should describe_solutions(expected)
          when :ask
            result.should == t.solutions ? RDF::Literal::TRUE : RDF::Literal::FALSE
          end
        end
      when MF.PositiveSyntaxTest, MF.PositiveSyntaxTest11,
           MF.NegativeSyntaxTest, MF.NegativeSyntaxTest11,
           UT.UpdateEvaluationTest, MF.UpdateEvaluationTest,
           MF.PositiveUpdateSyntaxTest11, MF.NegativeUpdateSyntaxTest11,
           MF.CSVResultFormatTest, MF.ServiceDescriptionTest, MF.ProtocolTest,
           MF.GraphStoreProtocolTest
        # Skip Other
      else
        it "??? #{t.entry} - #{t.name}" do
          puts t.inspect
          fail "Unknown test type #{t.type}"
        end
      end
    end
  end
end

describe SPARQL::Grammar::Parser do
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}
  describe "w3c dawg SPARQL 1.0 tests" do
    SPARQL::Spec.sparql1_0_tests(true).group_by(&:manifest).each do |man, tests|
      it_behaves_like "DAWG", man, tests
    end
  end

  describe "w3c dawg SPARQL 1.1 tests" do
    SPARQL::Spec.sparql1_1_tests(true).
      reject do |tc|
        %w{
          basic-update
          clear
          copy
          csv-tsv
          csv-tsv-res
          delete
          drop
          entailment
          http
          json
          json-res
          move
          protocol
          service
          syntax-fed

          aggregates
          bindings
          property-path
          subquery
          exists
          negation
        }.include? tc.manifest.to_s.split('/')[-2]
      end.
      group_by(&:manifest).
      each do |man, tests|
      it_behaves_like "DAWG", man, tests
    end
  end
end unless ENV['CI']
