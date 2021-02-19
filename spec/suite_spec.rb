$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'suite_helper'
require 'rdf/rdfxml'

shared_examples "SUITE" do |id, label, comment, tests|
  man_name = id.to_s.split("/")[-2]
  describe [man_name, label, comment].compact.join(" - ") do
    tests.each do |t|
      next unless t.action
      case t.type
      when 'mf:QueryEvaluationTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          case t.name
          when 'Basic - Term 6', 'Basic - Term 7'
            skip "Decimal format changed in SPARQL 1.1"
          when 'datatype-2 : Literals with a datatype'
            skip "datatype now returns rdf:langString for language-tagged literals"
          when /REDUCED/
            skip "REDUCED equivalent to DISTINCT"
          when 'Strings: Distinct', 'All: Distinct'
            skip "More compact representation"
          when /sq03/
            pending "Graph variable binding differences"
          when /pp11|pp31/
            pending "Expects multiple equivalent property path solutions"
          when 'date-1', /dawg-optional-filter-005-not-simplified/
            pending "Different results on unapproved tests" unless t.approved?
          end

          t.logger = RDF::Spec.logger
          result = sparql_query(graphs: t.graphs,
                                query: t.action.query_string,
                                base_uri: t.base_uri,
                                optimize: true,
                                form: t.form,
                                logger: t.logger)

          case t.form
          when :select
            expect(result).to be_a(RDF::Query::Solutions)
            if id.to_s =~ /sort/
              skip "JRuby sorting issue" if RUBY_ENGINE == 'jruby'
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
      when 'mf:CSVResultFormatTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          result = sparql_query(graphs: t.graphs,
                                query: t.action.query_string,
                                base_uri: t.base_uri,
                                form: t.form,
                                logger: t.logger)

          expect(result).to describe_csv_solutions(t.solutions)
          expect {result.to_csv}.not_to raise_error(StandardError)
        end
      when 'mf:PositiveSyntaxTest', 'mf:PositiveSyntaxTest11'
        it "positive syntax for #{t.entry} - #{t.name} - #{t.comment}" do
          skip "Spurrious error on Ruby < 2.0" if t.name == 'syntax-bind-02.rq'
          case t.name
          when 'Basic - Term 7', 'syntax-lit-08.rq'
            skip "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            skip "PNAME_LN changed in SPARQL 1.1"
          when 'dawg-optional-filter-005-simplified', 'dawg-optional-filter-005-not-simplified',
               'dataset-10'
            pending 'New problem with different manifest processing?'
          end
          expect do
            SPARQL.parse(t.action.query_string, base_uri: t.base_uri, validate: true, logger: t.logger)
          end.not_to raise_error(StandardError)
        end
      when 'mf:NegativeSyntaxTest', 'mf:NegativeSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          skip("Better Error Detection") if %w(
            agg08.rq agg09.rq agg10.rq agg11.rq agg12.rq
            syn-bad-pname-06.rq group06.rq group07.rq
          ).include?(t.entry)
          skip("Better Error Detection") if %w(
            syn-bad-01.rq syn-bad-02.rq
          ).include?(t.entry) && man_name == 'syntax-query'
          expect do
            SPARQL.parse(t.action.query_string, base_uri: t.base_uri, validate: true, logger: t.logger)
          end.to raise_error(StandardError)
        end
      when 'ut:UpdateEvaluationTest', 'mf:UpdateEvaluationTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          result = sparql_query(graphs: t.action.graphs,
                                query: t.action.query_string,
                                base_uri: t.base_uri,
                                form: t.form,
                                logger: t.logger)

          expect(result).to describe_solutions(t.expected, t)
        end
      when 'mf:PositiveUpdateSyntaxTest11'
        it "positive syntax test for #{t.entry} - #{t.name} - #{t.comment}" do
          pending("Whitespace in string tokens") if %w(
            syntax-update-26.ru syntax-update-27.ru syntax-update-28.ru
            syntax-update-36.ru
          ).include?(t.entry)
          expect do
            SPARQL.parse(t.action.query_string, base_uri: t.base_uri, update: true, validate: true, logger: t.logger)
          end.not_to raise_error(StandardError)
        end
      when 'mf:NegativeUpdateSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          expect do
            SPARQL.parse(t.action.query_string, base_uri: t.base_uri, update: true, validate: true, logger: t.logger)
          end.to raise_error(StandardError)
        end
      when 'mf:ServiceDescriptionTest', 'mf:ProtocolTest',
           'mf:GraphStoreProtocolTest'
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
  BASE = "http://w3c.github.io/rdf-tests/sparql11/"
  describe "w3c dawg SPARQL 1.0 syntax tests" do
    SPARQL::Spec.sparql1_0_syntax_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end

  describe "w3c dawg SPARQL 1.0 tests" do
    SPARQL::Spec.sparql1_0_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end

  describe "w3c dawg SPARQL 1.1 tests" do
    SPARQL::Spec.sparql1_1_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end

  describe "SPARQL-star tests" do
    SPARQL::Spec.sparql_star_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end
end unless ENV['CI']
