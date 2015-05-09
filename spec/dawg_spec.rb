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
            pending "Decimal format changed in SPARQL 1.1"
          when 'datatype-2 : Literals with a datatype'
            pending("datatype now returns rdf:langString for language-tagged literals")
          when /Cast to xsd:boolean/
            pending("figuring out why xsd:boolean doesn't behave according to http://www.w3.org/TR/rdf-sparql-query/#FunctionMapping")
          when /REDUCED/
            pending("REDUCED equivalent to DISTINCT")
          when /sq03/
            pending("Graph variable binding differences")
          when /pp11|pp31/
            pending("Expects multiple equivalent property path solutions")
          end

          result = sparql_query(graphs: t.graphs,
                                query: t.action.query_string,
                                base_uri: RDF::URI(t.action.query_file),
                                form: t.form)

          case t.form
          when :select
            expect(result).to be_a(RDF::Query::Solutions)
            if id.to_s =~ /sort/
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
                                base_uri: RDF::URI(t.action.query_file),
                                form: t.form)

          expect(result).to describe_csv_solutions(t.solutions)
          expect {result.to_csv}.not_to raise_error
        end
      when 'mf:PositiveSyntaxTest', 'mf:PositiveSyntaxTest11'
        it "positive syntax for #{t.entry} - #{t.name} - #{t.comment}" do
          expect {SPARQL.parse(t.action.query_string, validate: true)}.not_to raise_error
        end
      when 'mf:NegativeSyntaxTest', 'mf:NegativeSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          pending("Better Error Detection") if %w(
            syn-blabel-cross-graph-bad.rq syn-blabel-cross-optional-bad.rq syn-blabel-cross-union-bad.rq
            syn-bad-34.rq syn-bad-35.rq syn-bad-36.rq syn-bad-37.rq syn-bad-38.rq
            syn-bad-OPT-breaks-BGP.rq syn-bad-UNION-breaks-BGP.rq syn-bad-GRAPH-breaks-BGP.rq
            agg08.rq agg09.rq agg10.rq agg11.rq agg12.rq
            syntax-BINDscope6.rq syntax-BINDscope7.rq syntax-BINDscope8.rq
            syntax-SELECTscope2.rq
            syn-bad-pname-06.rq
          ).include?(t.entry)
          pending("Better Error Detection") if %w(
            syn-bad-01.rq syn-bad-02.rq
          ).include?(t.entry) && man_name == 'syntax-query'
          pending("New problem with different manifest processing?") if %w(
            group06.rq group07.rq
          ).include?(t.entry)
          expect {SPARQL.parse(t.action.query_string, validate: true)}.to raise_error
        end
      when 'ut:UpdateEvaluationTest', 'mf:UpdateEvaluationTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          # Load default and named graphs for result dataset
          expected = RDF::Repository.new do |r|
            t.result.graphs.each do |info|
              data, format = info[:data], info[:format]
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
                                base_uri: RDF::URI(t.action.query_file),
                                form: t.form)

          expect(result).to describe_solutions(expected, t)
        end
      when 'mf:PositiveUpdateSyntaxTest11'
        it "positive syntax test for #{t.entry} - #{t.name} - #{t.comment}" do
          pending("Whitespace in string tokens") if %w(
            syntax-update-26.ru syntax-update-27.ru syntax-update-28.ru
            syntax-update-36.ru
          ).include?(t.entry)
          expect {SPARQL.parse(t.action.query_string, update: true, validate: true)}.not_to raise_error
        end
      when 'mf:NegativeUpdateSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          expect {SPARQL.parse(t.action.query_string, update: true, validate: true)}.to raise_error
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
    main_man = SPARQL::Spec::Manifest.open(SPARQL::Spec.sparql1_0_tests)
    main_man.include.each do |man|
      it_behaves_like "DAWG", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'], man.entries
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
      it_behaves_like "DAWG", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'], man.entries
    end
  end
end unless ENV['CI']
