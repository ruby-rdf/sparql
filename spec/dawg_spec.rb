$:.unshift File.expand_path("..", __FILE__)
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
          when /sq03/
            pending("Graph variable binding differences")
          end
          pending "Property Paths" if man.to_s.split("/")[-2] == 'property-path'

          result = sparql_query(graphs: t.graphs,
                                query: t.action.query_string,
                                base_uri: t.action.query_file,
                                form: t.form)

          case t.form
          when :select
            expect(result).to be_a(RDF::Query::Solutions)
            if man.to_s =~ /sort/
              expect(result).to describe_ordered_solutions(t.solutions)
            else
              expect(result).to describe_solutions(t.solutions, t)
            end
          when :create, :describe, :construct
            expect(result).to be_a(RDF::Queryable)
            expect(result).to describe_solutions(t.solutions, t)
          when :ask
            expect(result).to eq t.solutions
          end
        end
      when MF.CSVResultFormatTest
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          result = sparql_query(graphs: t.graphs,
                                query: t.action.query_string,
                                base_uri: t.action.query_file,
                                form: t.form)

          expect(result).to describe_csv_solutions(t.solutions)
          expect {result.to_csv}.not_to raise_error
        end
      when UT.UpdateEvaluationTest, MF.UpdateEvaluationTest
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}", pending: "Update Operators" do

          # Load default and named graphs for result dataset
          expected = RDF::Repository.new do |r|
            t.result.graphs.each do |info|
              data, format, default = info[:data], info[:format]
              if data
                RDF::Reader.for(format).new(data, info).each_statement do |st|
                  st.context = RDF::URI(info[:base_uri]) if info[:base_uri]
                  r << st
                end
              end
            end
          end

          result = sparql_query(graphs: t.action.graphs,
                                query: t.action.query_string,
                                base_uri: t.action.query_file,
                                form: t.form)

          expect(result).to describe_solutions(expected, t)
        end
      when MF.PositiveSyntaxTest, MF.PositiveSyntaxTest11,
           MF.NegativeSyntaxTest, MF.NegativeSyntaxTest11,
           MF.PositiveUpdateSyntaxTest11, MF.NegativeUpdateSyntaxTest11,
           MF.ServiceDescriptionTest, MF.ProtocolTest,
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

describe SPARQL do
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
          delete
          drop
          move
          syntax-update-1
          syntax-update-2
          update-silent

          entailment

          csv-tsv-res
          http-rdf-dupdate
          protocol
          service
          syntax-fed
        }.include? tc.manifest.to_s.split('/')[-2]
      end.
      group_by(&:manifest).
      each do |man, tests|
      it_behaves_like "DAWG", man, tests
    end
  end
end unless ENV['CI']
