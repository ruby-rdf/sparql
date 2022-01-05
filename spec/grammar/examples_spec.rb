$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'strscan'

describe SPARQL::Grammar do
  describe "Examples" do
    def self.read_examples
      examples = []
      readme = File.expand_path("../../../lib/sparql/grammar.rb", __FILE__)
      # Get comment lines and remove leading comment
      doc = File.open(readme).readlines.map do |l|
        l.match(/^\s+#\s(.*)$/) && $1
      end.compact.join("\n")
      scanner = StringScanner.new(doc)
      scanner.skip_until(/^SPARQL:$/)
      until scanner.eos?
        current = {}
        current[:sparql] = scanner.scan_until(/^SXP:$/)[0..-5].strip
        current[:sxp]    = scanner.scan_until(/^(SPARQL:)|(## Implementation Notes)$/).
          sub(/^(SPARQL:)|(## Implementation Notes)$/, '').strip
        examples << current
        break if scanner.matched =~ /Implementation Notes/
      end
      examples
    end

    read_examples.each do |example|
      describe "query #{example[:sparql]}" do
        let(:update) {example[:sxp].include?('(update')}
        subject {parse(example[:sparql], update: update)}

        it "parses to #{example[:sxp]}" do
          is_expected.to eq SPARQL::Algebra.parse(example[:sxp])
        end
      end
    end

    def parse(query, **options)
      parser = SPARQL::Grammar::Parser.new(query)
      parser.parse(options[:update] ? :UpdateUnit: :QueryUnit)
    end

    context "Operator Examples" do
      def self.read_operator_examples
        examples = {}
        Dir.glob(File.expand_path("../../../lib/sparql/algebra/operator/*.rb", __FILE__)).each do |rb|
          op = File.basename(rb, ".rb")
          scanner = StringScanner.new(File.read(rb))
          while scanner.skip_until(/# @example SPARQL Grammar(.*)$/)
            current = {}
            current[:sparql] = scanner.scan_until(/# @example SSE/)[0..-14].gsub(/^\s*#/, '')
            current[:sxp]    = scanner.scan_until(/^\s+#\s*$/).gsub(/^\s*#/, '')
            current[:prod]   = current[:sxp].include?('(update') ? :UpdateUnit : :QueryUnit
            (examples[op] ||= []) << current
          end
        end
        examples
      end

      read_operator_examples.each do |op, examples|
        describe "Operator #{op}:" do
          examples.each do |example|
            sxp, sparql, production = example[:sxp], example[:sparql], example[:prod]
            it(sparql) do
              pending "not implemented yet" if %w(
              
              ).include?(op)
              expect(sparql).to generate(sxp, resolve_iris: false, production: production, validate: true)
            end
          end
        end
      end
    end
  end
end