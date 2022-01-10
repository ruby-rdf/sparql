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
          case t.entry
          when 'term-6.rq', 'term-7.rq'
            skip "Decimal format changed in SPARQL 1.1"
          when 'reduced-1.rq', 'reduced-2.rq'
            skip "REDUCED equivalent to DISTINCT"
          when 'distinct-1.rq'
            skip "More compact representation"
          when 'q-datatype-2.rq'
            skip "datatype now returns rdf:langString for language-tagged literals"
          when /sq03/
            pending "Graph variable binding differences"
          when 'pp11.rq', 'path-p2.rq'
            pending "Expects multiple equivalent property path solutions"
          when 'date-1.rq', 'expr-5.rq'
            pending "Different results on unapproved tests" unless t.name.include?('dawg-optional-filter-005-simplified')
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
          case t.entry
          when 'term-7.rq', 'syntax-lit-08.rq'
            skip "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            skip "PNAME_LN changed in SPARQL 1.1"
          end
          expect do
            SPARQL.parse(t.action.query_string, base_uri: t.base_uri, validate: true, logger: t.logger)
          end.not_to raise_error(StandardError)
        end
      when 'mf:NegativeSyntaxTest', 'mf:NegativeSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          pending("Better Error Detection") if %w(
            agg08.rq agg09.rq agg10.rq agg11.rq agg12.rq
            syn-bad-pname-06.rq group06.rq group07.rq
          ).include?(t.entry)
          pending("Better Error Detection") if %w(
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

shared_examples "to_sparql" do |id, label, comment, tests|
  man_name = id.to_s.split("/")[-2]
  describe [man_name, label, comment].compact.join(" - ") do
    tests.each do |t|
      next unless t.action
      case t.type
      when 'mf:QueryEvaluationTest', 'mf:PositiveSyntaxTest', 'mf:PositiveSyntaxTest11'
        it "Round Trips #{t.entry} - #{t.name}: #{t.comment}" do
          case t.entry
          when 'syntax-expr-05.rq', 'syntax-order-05.rq', 'syntax-function-04.rq'
            pending("Unregistered function calls")
          when 'term-7.rq', 'syntax-lit-08.rq'
            skip "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            skip "PNAME_LN changed in SPARQL 1.1"
          when 'bind05.rq', 'bind08.rq', 'syntax-bind-02.rq', 'strbefore02.rq'
            skip "Equivalent form"
          when 'exists03.rq', 'exists04.rq', 'exists05.rq'
            skip('TODO Exists')
          when 'agg-groupconcat-1.rq', 'agg-groupconcat-2.rq', 'agg-groupconcat-3.rq',
              'agg-sample-01.rq', 'sq03.rq', 'sq08.rq', 'sq09.rq', 'sq11.rq', 'sq12.rq',
              'sq13.rq', 'sq14.rq', 'syntax-SELECTscope1.rq', 'syntax-SELECTscope3.rq'
            pending("TODO SubSelect")
          when 'agg-err-01.rq'
            pending "TODO key not found"
          when 'pp06.rq', 'path-ng-01.rq', 'path-ng-02.rq'
            pending "TODO graph name on property path"
          when 'pp09.rq', 'pp10.rq', 'path-p2.rq', 'path-p4.rq'
            pending "TODO property path grouping"
          when 'syntax-bindings-02a.rq', 'syntax-bindings-03a.rq', 'syntax-bindings-05a.rq'
            pending "TODO top-level values"
          when 'syn-pname-05.rq', 'syn-pname-06.rq', 'syn-pname-07.rq', 'syn-codepoint-escape-01.rq',
               '1val1STRING_LITERAL1_with_UTF8_boundaries.rq', '1val1STRING_LITERAL1_with_UTF8_boundaries_escaped.rq'
            pending "TODO escaping"
          when 'syn-pp-in-collection.rq'
            pending "TODO runtime error and list representation"
          when 'strafter02.rq '
            pending "TODO odd project multple bindings"
          end
          t.logger = RDF::Spec.logger
          t.logger.debug "Source:\n#{t.action.query_string}"
          sse = SPARQL.parse(t.action.query_string, base_uri: t.base_uri)
          sparql = sse.to_sparql(base_uri: t.base_uri)
          expect(sparql).to generate(sse,
                                     base_uri: t.base_uri,
                                     resolve_iris: false,
                                     production: :QueryUnit,
                                     logger: t.logger)
        end
      when 'ut:UpdateEvaluationTest', 'mf:UpdateEvaluationTest', 'mf:PositiveUpdateSyntaxTest11'
        it "Round Trips #{t.entry} - #{t.name}: #{t.comment}" do
          case t.entry
          when 'insert-05a.ru', 'insert-data-same-bnode.ru',
              'insert-where-same-bnode.ru', 'insert-where-same-bnode2.ru',
              'delete-insert-04.ru'
            pending("SubSelect")
          when 'delete-insert-04b.ru', 'delete-insert-05b.ru', 'delete-insert-05b.ru'
            pending "TODO sub-joins"
          when 'syntax-update-38.ru'
            pending "empty query"
          when 'large-request-01.ru'
            skip "large request"
          end
          pending("Whitespace in string tokens") if %w(
            syntax-update-26.ru syntax-update-27.ru syntax-update-28.ru
            syntax-update-36.ru
          ).include?(t.entry)
          t.logger = RDF::Spec.logger
          t.logger.debug "Source:\n#{t.action.query_string}\n"
          sse = SPARQL.parse(t.action.query_string,
                             base_uri: t.base_uri,
                             update: true)
          sparql = sse.to_sparql(base_uri: t.base_uri)
          expect(sparql).to generate(sse,
                                     base_uri: t.base_uri,
                                     resolve_iris: false,
                                     production: :UpdateUnit,
                                     logger: t.logger)
        end
      when 'mf:NegativeSyntaxTest', 'mf:NegativeSyntaxTest11', 'mf:NegativeUpdateSyntaxTest11'
        # Do nothing.
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
        it_behaves_like "to_sparql", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end

  describe "w3c dawg SPARQL 1.0 tests" do
    SPARQL::Spec.sparql1_0_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
        it_behaves_like "to_sparql", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end

  describe "w3c dawg SPARQL 1.1 tests" do
    SPARQL::Spec.sparql1_1_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
        it_behaves_like "to_sparql", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end

  describe "SPARQL-star tests" do
    SPARQL::Spec.sparql_star_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
        #it_behaves_like "to_sparql", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end
end unless ENV['CI']
