$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'suite_helper'
require 'rdf/rdfxml'

shared_examples "SUITE" do |id, label, comment, tests|
  man_name = id.to_s.split("/")[-2]
  describe [man_name, label, comment].compact.join(" - ") do
    tests.each do |t|
      next unless t.action
      t.logger = RDF::Spec.logger
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
            # See https://github.com/w3c/rdf-tests/pull/83#issuecomment-1324220844 for @afs's discussion of the simplified/not-simplified issue.
            pending "Different results on unapproved tests" unless t.name.include?('dawg-optional-filter-005-simplified')
          when 'csvtsv02.rq'
            pending "empty values are the same as missing values"
          when 'construct_date-02.rq', 'construct_time-01.rq'
            pending "failed when simplifying whitespace in terminals"
          when 'nps_inverse.rq', 'nps_direct_and_inverse.rq'
            pending("New SPARQL tests")
          end

          skip 'Entailment Regimes' if t.entailment?
          skip "Federated Query" if Array(t.feature).include?('sd:BasicFederatedQuery')

          result = sparql_query(graphs: t.graphs,
                                query: t.action.query_string,
                                base_uri: t.base_uri,
                                optimize: true,
                                all_vars: true,
                                form: t.form,
                                logger: t.logger)

          case t.form
          when :select
            expect(result).to be_a(RDF::Query::Solutions)
            if id.to_s =~ /sort/
              skip "JRuby sorting issue" if RUBY_ENGINE == 'jruby'
              expect(result).to describe_ordered_solutions(t.solutions, t)
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
                                all_vars: true,
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
            SPARQL.parse(t.action.query_string,
                         base_uri: t.base_uri,
                         all_vars: true,
                         validate: true,
                         logger: t.logger)
          end.not_to raise_error(StandardError)
        end
      when 'mf:NegativeSyntaxTest', 'mf:NegativeSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          pending("Raw PNAME validation") if %w(syn-bad-pname-06.rq).include?(t.entry)
          expect do
            SPARQL.parse(t.action.query_string,
                         base_uri: t.base_uri,
                         all_vars: true,
                         validate: true,
                         logger: t.logger)
          end.to raise_error(StandardError)
        end
      when 'ut:UpdateEvaluationTest', 'mf:UpdateEvaluationTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          result = sparql_query(graphs: t.action.graphs,
                                query: t.action.query_string,
                                base_uri: t.base_uri,
                                all_vars: true,
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
            SPARQL.parse(t.action.query_string,
                         base_uri: t.base_uri,
                         all_vars: true,
                         update: true,
                         validate: true,
                         logger: t.logger)
          end.not_to raise_error(StandardError)
        end
      when 'mf:NegativeUpdateSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          expect do
            SPARQL.parse(t.action.query_string, base_uri: t.base_uri, update: true, validate: true, logger: t.logger)
          end.to raise_error(StandardError)
        end
      when 'mf:ProtocolTest'
        it "#{t.type} #{t.entry} - #{t.name}" do
          case t.entry
          when 'bad_query_non_utf8', 'bad_update_non_utf8'
            skip "Rack doesn't honor input encoding"
          end
          expect(t.execute).to produce(true, logger: t.logger)
        end
      when 'mf:GraphStoreProtocolTest'
        it "#{t.type} #{t.entry} - #{t.name}" do
          skip t.type
        end
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
      next if %w(mf:ProtocolTest).include?(t.type)
      case t.type
      when 'mf:QueryEvaluationTest', 'mf:PositiveSyntaxTest', 'mf:PositiveSyntaxTest11', 'mf:CSVResultFormatTest'
        it "Round Trips #{t.entry} - #{t.name}: #{t.comment}" do
          case t.entry
          when 'syntax-expr-05.rq', 'syntax-order-05.rq', 'syntax-function-04.rq'
            pending("Unregistered function calls")
          when 'term-6.rq', 'term-7.rq', 'syntax-lit-08.rq'
            skip "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            skip "PNAME_LN changed in SPARQL 1.1"
          when 'bind05.rq', 'bind08.rq', 'syntax-bind-02.rq', 'strbefore02.rq',
               'agg-groupconcat-1.rq', 'agg-groupconcat-2.rq',
               'sq08.rq', 'sq12.rq', 'sq13.rq',
               'syntax-SELECTscope1.rq', 'syntax-SELECTscope3.rq',
               'sparql-star-annotation-06.rq'
            skip "Equivalent form"
          when 'sq09.rq', 'sq14.rq'
            pending("SubSelect")
          when 'service03.rq', 'service06.rq', 'syntax-service-01.rq'
            pending("Service")
          when 'sparql-star-order-by.rq'
            pending("OFFSET/LIMIT in sub-select")
          when 'compare_time-01.rq',
               'adjust_dateTime-01.rq', 'adjust_date-01.rq', 'adjust_time-01.rq'
            skip "Equivalent form"
          when 'nps_inverse.rq', 'nps_direct_and_inverse.rq'
            pending("New SPARQL tests")
          when 'values04.rq', 'values05.rq', 'values08.rq'
            skip("Invalid VALUES Syntax")
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
          when 'syntax-update-38.ru'
            pending "empty query"
          when 'large-request-01.ru'
            skip "large request"
          when 'syntax-update-26.ru', 'syntax-update-27.ru', 'syntax-update-28.ru',
               'syntax-update-36.ru'
            pending("Whitespace in string tokens")
          when 'insert-05a.ru', 'insert-data-same-bnode.ru', 
               'insert-where-same-bnode.ru', 'insert-where-same-bnode2.ru',
               'sparql-star-syntax-update-7.ru'
            skip "Equivalent form"
          when 'delete-insert-04.ru'
            pending("SubSelect")
          end
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
  BASE = "http://w3c.github.io/rdf-tests/sparql/sparql11/"
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
        it_behaves_like "SUITE", man.attributes['id'], man.label, (path.match?(/protocol/) ? '' : man.comment), man.entries
        it_behaves_like "to_sparql", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end

  describe "SPARQL-star tests" do
    SPARQL::Spec.sparql_star_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
        it_behaves_like "to_sparql", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end

  describe "SPARQL-12 tests" do
    SPARQL::Spec.sparql_12_tests.each do |path|
      SPARQL::Spec::Manifest.open(path) do |man|
        it_behaves_like "SUITE", man.attributes['id'], man.label, man.comment, man.entries
        it_behaves_like "to_sparql", man.attributes['id'], man.label, man.comment, man.entries
      end
    end
  end
end unless ENV['CI']
