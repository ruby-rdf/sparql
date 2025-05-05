$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'strscan'

describe SPARQL::Grammar do
  def self.current_line_number(text, scanner); text[0..scanner.pos].count("\n") + 1; end
  describe "Examples" do
    def self.read_examples
      examples = []
      readme = File.expand_path("../../../lib/sparql/grammar.rb", __FILE__)
      doc = File.read(readme)
      scanner = StringScanner.new(doc)
      scanner.skip_until(/^\s+#\s+SPARQL:$/)
      until scanner.eos?
        current = {}
        current[:source] = "#{File.basename(readme)}:#{current_line_number(doc, scanner)}"
        current[:sparql] = scanner.scan_until(/^\s+#\s+SXP:$/)[0..-5].gsub(/^\s*#/, '').strip
        current[:sxp]    = scanner.scan_until(/^(\s+#\s+SPARQL:)|(## Implementation Notes)$/).gsub(/^\s*#/, '').
          sub(/^(\s+SPARQL:)|(## Implementation Notes)$/, '').strip
        examples << current
        break if scanner.matched =~ /Implementation Notes/
      end
      examples
    end

    read_examples.each do |example|
      describe "query #{example[:sparql]} # #{example[:source]}" do
        let(:update) {example[:sxp].include?('(update')}
        subject {parse(example[:sparql], update: update)}

        it "parses to #{example[:sxp]}" do
          is_expected.to generate(example[:sxp], {})
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
          doc = File.read(rb)
          scanner = StringScanner.new(doc)
          while scanner.skip_until(/# @example SPARQL Grammar(.*)$/)
            current = {}
            current[:source] = "#{op}.rb:#{current_line_number(doc, scanner)}"
            current[:sparql] = scanner.scan_until(/# @example SSE.*$/).gsub(/^\s*#/, '').sub(/@example SSE.*$/, '')
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
            describe("#{sparql} # #{example[:source]}") do
              let(:query) {parse(sparql, update: production == :UpdateUnit)}
              it "has the same number of triples" do
                q_sxp = query.to_sxp
                unquoted_count = q_sxp.split('(triple').length - 1
                result_count = sxp.split('(triple').length - 1
                expect(unquoted_count).to produce(result_count, [q_sxp])
              end

              it "has the same number of qtriples" do
                q_sxp = query.to_sxp
                quoted_count = q_sxp.split('(qtriple').length - 1
                result_count = sxp.split('(qtriple').length - 1
                expect(quoted_count).to produce(result_count, [q_sxp])
              end

              it "produces equivalent SXP" do
                expect(query).to generate(sxp, resolve_iris: false, production: production, validate: true)
              end
            end
          end
        end
      end
    end
  end
end
