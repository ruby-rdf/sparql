$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'strscan'

include SPARQL::Algebra

describe SPARQL::Algebra::Operator do
  it "reproduces simple query" do
    sxp = %{(prefix ((: <http://example/>))
            (bgp (triple :s :p :o)))}
    sse = SPARQL::Algebra.parse(sxp)
    sparql_result = sse.to_sparql
    expect(sparql_result).to generate(sxp, resolve_iris: false, validate: true)
  end

  context "Examples" do
    def self.read_examples
      examples = {}
      Dir.glob(File.expand_path("../../../lib/sparql/algebra/operator/*.rb", __FILE__)).each do |rb|
        op = File.basename(rb, ".rb")
        scanner = StringScanner.new(File.read(rb))
        while scanner.skip_until(/# @example SSE/)
          ex = scanner.scan_until(/^\s+#\s*$/)

          # Trim off comment prefix
          ex = ex.gsub(/^\s*#/, '')
          (examples[op] ||= []) << ex
        end
      end
      examples
    end

    read_examples.each do |op, examples|
      describe "Operator #{op}:" do
        examples.each do |sxp|
          it(sxp) do
            sse = SPARQL::Algebra.parse(sxp)
            sparql_result = sse.to_sparql
            production = sparql_result.match?(/ASK|SELECT|CONSTRUCT|DESCRIBE/) ? :QueryUnit : :UpdateUnit
            expect(sparql_result).to generate(sxp, resolve_iris: false, production: production, validate: true)
          end
        end
      end
    end
  end
end
