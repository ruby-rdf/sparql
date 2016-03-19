$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'dawg_helper'
require 'rdf/rdfxml'

shared_examples "DAWG" do |id, label, comment, tests|
  man_name = id.to_s.split("/")[-2]
  describe [man_name, label, comment].compact.join(" - ") do
    tests.each do |t|
      next unless t.approved?
      case t.type
      when 'mf:QueryEvaluationTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          case t.name
          when 'Basic - Term 6', 'Basic - Term 7'
            skip "Decimal format changed in SPARQL 1.1"
          when 'datatype-2 : Literals with a datatype'
            skip "datatype now returns rdf:langString for language-tagged literals"
          when /Cast to xsd:boolean/
            pending "figuring out why xsd:boolean doesn't behave according to http://www.w3.org/TR/rdf-sparql-query/#FunctionMapping"
          when /REDUCED/
            skip "REDUCED equivalent to DISTINCT"
          when /sq03/
            pending "Graph variable binding differences"
          when /pp11|pp31/
            pending "Expects multiple equivalent property path solutions"
          when /normalization-02/
            skip 'odd operator equality error'
          end

          result = sparql_query(graphs: t.graphs,
                                query: t.action.query_string,
                                base_uri: t.base_uri,
                                form: t.form)

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
                                form: t.form)

          expect(result).to describe_csv_solutions(t.solutions)
          expect {result.to_csv}.not_to raise_error
        end
      when 'mf:PositiveSyntaxTest', 'mf:PositiveSyntaxTest11'
        it "positive syntax for #{t.entry} - #{t.name} - #{t.comment}" do
          skip "Spurrious error on Ruby < 2.0" if t.name == 'syntax-bind-02.rq' && RUBY_VERSION < "2.0"
          case t.name
          when 'Basic - Term 7', 'syntax-lit-08.rq'
            skip "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            skip "PNAME_LN changed in SPARQL 1.1"
          when 'dawg-optional-filter-005-simplified', 'dawg-optional-filter-005-not-simplified',
               'dataset-10'
            pending 'New problem with different manifest processing?'
          end
          expect {SPARQL.parse(t.action.query_string, base_uri: t.base_uri, validate: true)}.not_to raise_error
        end
      when 'mf:NegativeSyntaxTest', 'mf:NegativeSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          pending("Better Error Detection") if %w(
            agg08.rq agg11.rq
            syn-bad-pname-06.rq
          ).include?(t.entry)
          expect {SPARQL.parse(t.action.query_string, base_uri: t.base_uri, validate: true)}.to raise_error
        end
      when 'ut:UpdateEvaluationTest', 'mf:UpdateEvaluationTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          # Load default and named graphs for result dataset
          expected = RDF::Repository.new do |r|
            t.result.graphs.each do |info|
              data, format = info[:data], info[:format]
              if data
                RDF::Reader.for(format).new(data, info).each_statement do |st|
                  st.graph_name = RDF::URI(info[:base_uri]) if info[:base_uri]
                  r << st
                end
              end
            end
          end

          result = sparql_query(graphs: t.action.graphs,
                                query: t.action.query_string,
                                base_uri: t.base_uri,
                                form: t.form)

          expect(result).to describe_solutions(expected, t)
        end
      when 'mf:PositiveUpdateSyntaxTest11'
        it "positive syntax test for #{t.entry} - #{t.name} - #{t.comment}" do
          pending("Whitespace in string tokens") if %w(
            syntax-update-26.ru syntax-update-27.ru syntax-update-28.ru
            syntax-update-36.ru
          ).include?(t.entry)
          expect {SPARQL.parse(t.action.query_string, base_uri: t.base_uri, update: true, validate: true)}.not_to raise_error
        end
      when 'mf:NegativeUpdateSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          expect {SPARQL.parse(t.action.query_string, base_uri: t.base_uri, update: true, validate: true)}.to raise_error
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
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}

  describe "w3c dawg SPARQL 1.0 tests" do
    main_man = SPARQL::Spec::Manifest.open(SPARQL::Spec.sparql1_0_syntax_tests)
    main_man.include.each do |man|
      it_behaves_like "DAWG", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'] || man.comment, man.entries
    end
  end

  describe "w3c dawg SPARQL 1.0 tests" do
    main_man = SPARQL::Spec::Manifest.open(SPARQL::Spec.sparql1_0_tests)
    main_man.include.each do |man|
      it_behaves_like "DAWG", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'] || man.comment, man.entries
    end
  end

  describe "w3c dawg SPARQL 1.1 tests" do
    main_man = SPARQL::Spec::Manifest.open(SPARQL::Spec.sparql1_1_tests)
    main_man.include.reject do |m|
      %w{
        entailment
        
        csv-tsv-res
        http-rdf-dupdate
        protocol
        service
        syntax-fed
      }.include?(m.attributes['id'].to_s.split('/')[-2])
    end.each do |man|
      it_behaves_like "DAWG", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'] || man.comment, man.entries
    end
  end
end unless ENV['CI'] && (RUBY_VERSION < "2.0" || RUBY_ENGINE == 'rbx')
