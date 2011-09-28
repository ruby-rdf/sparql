$:.unshift ".."
require 'spec_helper'
require 'strscan'

describe SPARQL::Algebra do
  include SPARQL::Algebra
  describe "Examples" do
    def self.read_examples
      examples = []
      readme = File.join(File.expand_path(File.dirname(__FILE__)), "..", "..", "lib", "sparql", "algebra.rb")
      # Get comment lines and remove leading comment
      doc = File.open(readme).readlines.map do |l|
        l.match(/^\s+#\s(.*)$/) && $1
      end.compact.join("\n")
      scanner = StringScanner.new(doc)
      scanner.skip_until(/^## Basic Query$/)
      until scanner.eos?
        current = {:type => :query}
        current[:sparql] = scanner.scan_until(/^is equivalent to$/)[0..-17].strip
        current[:sxp]    = scanner.scan_until(/^#.*$/).sub(/^#.*$/, '').strip
        examples << current
        break if scanner.matched =~ /^# Expressions/
      end
      
      # Expression examples
      scanner.skip_until(/^## Constructing operator expressions manually$/)
      until scanner.eos?
        line = scanner.scan_until(/ .*/).strip
        break if line =~ /Evaluating expressions on a solution sequence/
        next if line =~ /^\s*(#.*)?$/
        current = {:type => :expression}
        expr, result = line.to_s.split('#=>').map(&:strip)
        current[:expr] = expr
        current[:expected] = result
        examples << current
      end

      examples
    end

    read_examples.each do |example|
      if example[:type] == :query
        describe "query #{example[:sparql]}" do
          subject { parse(example[:sparql])}

          it "parses to #{example[:sxp]}" do
            subject.should == SPARQL::Algebra.parse(example[:sxp])
          end
        end
      else
        describe "expression #{example[:expr]}" do
          if example[:expected]
            it "produces #{example[:expected]}" do
              eval(example[:expr]).should == eval(example[:expected])
            end
          else
            it "evaluates to Expression" do
              eval(example[:expr]).should be_a(Expression)
            end
          end
        end
      end
    end

    def parse(query, options = {})
      parser = SPARQL::Grammar::Parser.new(query)
      parser.parse
    end
  end
end