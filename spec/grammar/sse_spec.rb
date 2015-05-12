$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'dawg_helper'

shared_examples "SSE" do |id, label, comment, tests|
  man_name = id.to_s.split("/")[-2]
  describe [man_name, label, comment].compact.join(" - ") do
    tests.each do |t|
      next unless t.approved?
      case t.type
      when "mf:QueryEvaluationTest", 'mf:PositiveSyntaxTest', 'mf:PositiveSyntaxTest11'
        it "parses #{t.entry} - #{t.name} - #{t.comment} to correct SXP" do
          case t.name
          when 'Basic - Term 7', 'syntax-lit-08.rq'
            skip "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            skip "PNAME_LN changed in SPARQL 1.1"
          when 'dawg-optional-filter-005-simplified', 'dawg-optional-filter-005-not-simplified',
               'dataset-10'
            pending 'New problem with different manifest processing?'
          end
          parser_opts = {base_uri: t.base_uri, validate: true}
          parser_opts[:debug] = true if ENV['PARSER_DEBUG']
          query = SPARQL::Grammar.parse(t.action.query_string, parser_opts)
          sxp = SPARQL::Algebra.parse(t.action.sse_string, parser_opts)
          expect(query).to eq sxp
        end

        it "parses #{t.entry} - #{t.name} - #{t.comment} to lexically equivalent SSE" do
          case t.name
          when 'Basic - Term 6', 'Basic - Term 7', 'syntax-lit-08.rq'
            skip "Decimal format changed in SPARQL 1.1"
          when 'syntax-esc-04.rq', 'syntax-esc-05.rq'
            skip "PNAME_LN changed in SPARQL 1.1"
          when 'syn-pp-in-collection'
            pending "Investigate unusual inequality"
          end
          query = begin
            SPARQL::Grammar.parse(t.action.query_string, validate: true, base_uri: t.base_uri, debug: ENV['PARSER_DEBUG'])
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
          expect(normalized_query).to produce(normalized_result, ["original query:", t.action.query_string])
        end
      when 'mf:NegativeSyntaxTest', 'mf:NegativeSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          pending("Better Error Detection") if %w(
            agg08.rq agg09.rq agg10.rq agg11.rq agg12.rq
            syn-bad-pname-06.rq
          ).include?(t.entry)
          pending("Better Error Detection") if %w(
            syn-bad-01.rq syn-bad-02.rq
          ).include?(t.entry) && man_name == 'syntax-query'
          pending("New problem with different manifest processing?") if %w(
            group06.rq group07.rq
          ).include?(t.entry)
          expect {SPARQL::Grammar.parse(t.action.query_string, base_uri: t.base_uri, validate: true)}.to raise_error
        end
      when 'ut:UpdateEvaluationTest', 'mf:UpdateEvaluationTest', 'mf:PositiveUpdateSyntaxTest11'
        it "parses #{t.entry} - #{t.name} - #{t.comment} to correct SXP" do
          pending("Whitespace in string tokens") if %w(
            syntax-update-26.ru syntax-update-27.ru syntax-update-28.ru
            syntax-update-36.ru
          ).include?(t.entry)
          pending("Null update corner case") if %w(
            syntax-update-38.ru
          ).include?(t.entry)
          parser_opts = {base_uri: t.base_uri, validate: true}
          parser_opts[:debug] = true if ENV['PARSER_DEBUG']
          query = SPARQL::Grammar.parse(t.action.query_string, parser_opts.merge(update: true))
          sxp = SPARQL::Algebra.parse(t.action.sse_string, parser_opts)
          expect(query).to eq sxp
        end

        it "parses #{t.entry} - #{t.name} - #{t.comment} to lexically equivalent SSE" do
          pending("Whitespace in string tokens") if %w(
            syntax-update-26.ru syntax-update-27.ru syntax-update-28.ru
            syntax-update-36.ru
          ).include?(t.entry)
          pending("Null update corner case") if %w(
            syntax-update-38.ru
          ).include?(t.entry)
          query = begin
            SPARQL::Grammar.parse(t.action.query_string, base_uri: t.base_uri, validate: true, update: true, debug: ENV['PARSER_DEBUG'])
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
          expect(normalized_query).to produce(normalized_result, ["original query:", t.action.query_string])
        end
      when 'mf:NegativeUpdateSyntaxTest11'
        it "detects syntax error for #{t.entry} - #{t.name} - #{t.comment}" do
          expect {SPARQL::Grammar.parse(t.action.query_string, base_uri: t.base_uri, update: true, validate: true)}.to raise_error
        end
      when 'mf:CSVResultFormatTest', 'mf:ServiceDescriptionTest', 'mf:ProtocolTest',
           'mf:GraphStoreProtocolTest'
        it "parses #{t.entry} - #{t.name} to correct SSE - #{t.comment}"
        it "parses #{t.entry} - #{t.name} to lexically equivalent SSE - #{t.comment}"
      else
        it "??? #{t.entry} - #{t.name} - #{t.comment}" do
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
    main_man = SPARQL::Spec::Manifest.open(SPARQL::Spec.sparql1_0_syntax_tests)
    main_man.include.each do |man|
      it_behaves_like "SSE", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'] || man.comment, man.entries
    end
  end

  describe "w3c dawg SPARQL 1.0 tests" do
    main_man = SPARQL::Spec::Manifest.open(SPARQL::Spec.sparql1_0_tests)
    main_man.include.each do |man|
      it_behaves_like "SSE", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'] || man.comment, man.entries
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
      it_behaves_like "SSE", man.attributes['id'], man.attributes['rdfs:label'], man.attributes['rdfs:comment'] || man.comment, man.entries
    end
  end
end unless ENV['CI']