$:.unshift ".."
require 'spec_helper'
require 'strscan'

describe SPARQL::Grammar do
  describe "Examples" do
    def self.read_examples
      examples = []
      readme = File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "lib", "sparql", "grammar.rb")
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
        subject { parse(example[:sparql])}

        it "parses to #{example[:sxp]}" do
          should == SPARQL::Algebra.parse(example[:sxp])
        end
      end
    end

    def parse(query, options = {})
      parser = SPARQL::Grammar::Parser.new(query)
      parser.parse
    end
  end
end