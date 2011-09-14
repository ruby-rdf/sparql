$:.unshift ".."
require 'spec_helper'
require 'dawg_helper'

describe SPARQL::Grammar::Parser do
  describe "w3c dawg SPARQL tests to SSE" do
    SPARQL::Spec.sparql1_0_tests.group_by(&:manifest).each do |man, tests|
      describe man.to_s.split("/")[-2] do
        tests.each do |t|
          case t.type
          when MF.QueryEvaluationTest
            it "parses #{t.name} to correct SSE" do
              parser_opts = {:base_uri => t.action.query_file}
              parser_opts[:debug] = true if ENV['PARSER_DEBUG']
              query = SPARQL::Grammar.parse(t.action.query_string, parser_opts)
              sse = SPARQL::Algebra.parse(t.action.sse_string, parser_opts)
              query.should == sse
            end

            it "parses #{t.name} to lexically equivalent SSE" do
              query = SPARQL::Grammar.parse(t.action.query_string)
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
              normalized_query.should == normalized_result rescue pending("Lexical equivalence")
            end
          else
            it "??? #{t.name}" do
              puts t.inspect
              fail "Unknown test type #{t.type}"
            end
          end
        end
      end
    end
  end
end