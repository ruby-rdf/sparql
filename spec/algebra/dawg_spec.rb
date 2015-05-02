$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'dawg_helper'
require 'rdf/rdfxml'

shared_examples "DAWG-SSE" do |id, label, comment, tests|
  man_name = id.to_s.split("/")[-2]
  describe [man_name, label, comment].compact.join(" - ") do
    tests.each do |t|
      next unless t.approved?
      case t.type
      when 'mf:QueryEvaluationTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
          case t.name
          when 'datatype-2 : Literals with a datatype'
            pending("datatype now returns rdf:langString for language-tagged literals")
          when /Cast to xsd:boolean/
            pending("figuring out why xsd:boolean doesn't behave according to http://www.w3.org/TR/rdf-sparql-query/#FunctionMapping")
          when /REDUCED/
            pending("REDUCED equivalent to DISTINCT")
          when /sq03/
            pending("Graph variable binding differences")
          end
          pending "Property Paths" if id.to_s.split("/")[-2] == 'property-path'

          result = sparql_query(graphs: t.graphs,
                                query: t.action.sse_string,
                                base_uri: RDF::URI(t.action.query_file),
                                repository: "sparql-spec",
                                form: t.form,
                                sse: true)

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
                                query: t.action.sse_string,
                                base_uri: RDF::URI(t.action.query_file),
                                repository: "sparql-spec",
                                form: t.form,
                                sse: true)

          expect(result).to describe_csv_solutions(t.solutions)
          expect {result.to_csv}.not_to raise_error
        end
      when 'ut:UpdateEvaluationTest', 'mf:UpdateEvaluationTest'
        it "evaluates #{t.entry} - #{t.name}: #{t.comment}" do
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
                                query: t.action.sse_string,
                                base_uri: RDF::URI(t.action.query_file),
                                repository: "sparql-spec",
                                form: t.form,
                                sse: true)

          #require 'byebug'; byebug
          expect(result).to describe_solutions(expected, t)
        end
      when 'mf:PositiveSyntaxTest', 'mf:PositiveSyntaxTest11',
           'mf:NegativeSyntaxTest', 'mf:NegativeSyntaxTest11',
           'mf:PositiveUpdateSyntaxTest11', 'mf:NegativeUpdateSyntaxTest11',
           'mf:ServiceDescriptionTest', 'mf:ProtocolTest',
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

describe SPARQL::Algebra do
  describe "w3c dawg SPARQL 1.0 tests" do
    main_man = SPARQL::Spec::Manifest.open(SPARQL::Spec.sparql1_0_tests)
    main_man.include.each do |man|
      it_behaves_like "DAWG-SSE", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'], man.entries
    end
  end

  describe "w3c dawg SPARQL 1.1 tests" do
    main_man = SPARQL::Spec::Manifest.open(SPARQL::Spec.sparql1_1_tests)
    main_man.include.reject do |m|
      %w{
        basic-update
        delete delete-data delete-insert delete-where
        syntax-update-1
        syntax-update-2
  
        entailment
  
        http-rdf-dupdate
        protocol
        service
        syntax-fed
      }.include? m.attributes['id'].to_s.split('/')[-2]
    end.each do |man|
      it_behaves_like "DAWG-SSE", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'], man.entries
    end
  end
end unless ENV['CI']