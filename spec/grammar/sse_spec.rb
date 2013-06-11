$:.unshift ".."
require 'spec_helper'
require 'dawg_helper'

shared_examples "SSE" do |man, tests|
  describe man.to_s.split("/")[-2] do
    tests.each do |t|
      case t.type
      when MF.QueryEvaluationTest, MF.PositiveSyntaxTest, MF.PositiveSyntaxTest11
        it "parses #{t.entry} - #{t.name} to correct SSE" do
          case t.name
          when 'Basic - Term 6', 'Basic - Term 7', 'syntax-lit-08.rq'
            pending "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            pending "Fixing PNAME_LN not matching :\\u0070"
          end
          parser_opts = {:base_uri => t.action.query_file}
          parser_opts[:debug] = true if ENV['PARSER_DEBUG']
          query = SPARQL::Grammar.parse(t.action.query_string, parser_opts)
          sse = SPARQL::Algebra.parse(t.action.sse_string, parser_opts)
          query.should == sse
        end

        it "parses #{t.entry} - #{t.name} to lexically equivalent SSE" do
          case t.name
          when 'Basic - Term 6', 'Basic - Term 7', 'syntax-lit-08.rq'
            pending "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            pending "Fixing PNAME_LN not matching :\\u0070"
          end
          query = begin
            SPARQL::Grammar.parse(t.action.query_string, :debug => ENV['PARSER_DEBUG'])
          rescue Exception => e
            "Error: #{e.message}"
          end
          normalized_query = query.to_sxp.
            gsub(/\s+/m, " ").
            gsub(/\(\s+\(/, '((').
            gsub(/\)\s+\)/, '))').
            strip
          normalized_result = t.action.sse_string.
            gsub(/\s+/m, " ").
            gsub(/\(\s+\(/, '((').
            gsub(/\)\s+\)/, '))').
            strip
          normalized_query.should produce(normalized_result, ["original query:", t.action.query_string])
        end
      when MF.NegativeSyntaxTest, MF.NegativeSyntaxTest11
        it "detects syntax error for #{t.entry} - #{t.name}" do
          begin
            lambda {SPARQL::Grammar.parse(t.action.query_string, :validate => true)}.should raise_error
          rescue
            pending "Detecting syntax errors better"
          end
        end
      when UT.UpdateEvaluationTest, MF.UpdateEvaluationTest,
           MF.PositiveUpdateSyntaxTest11, MF.NegativeUpdateSyntaxTest11,
           MF.CSVResultFormatTest, MF.ServiceDescriptionTest, MF.ProtocolTest,
           MF.GraphStoreProtocolTest
        it "parses #{t.entry} - #{t.name} to correct SSE"
        it "parses #{t.entry} - #{t.name} to lexically equivalent SSE"
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
  describe "w3c dawg SPARQL 1.0 syntax tests" do
    SPARQL::Spec.sparql1_0_syntax_tests(true).group_by(&:manifest).each do |man, tests|
      it_behaves_like "SSE", man, tests
    end
  end

  describe "w3c dawg SPARQL 1.0 tests" do
    SPARQL::Spec.sparql1_0_tests(true).group_by(&:manifest).each do |man, tests|
      it_behaves_like "SSE", man, tests
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

          property-path

          entailment

          csv-tsv-res
          http-rdf-dupdate
          json-res
          protocol
          service
          syntax-fed

          negation
          syntax-query
        }.include? tc.manifest.to_s.split('/')[-2]
      end.
      group_by(&:manifest).
      each do |man, tests|
      it_behaves_like "SSE", man, tests
    end
  end
end unless ENV['CI']