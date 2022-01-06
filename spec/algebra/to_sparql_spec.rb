$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'strscan'

include SPARQL::Algebra

shared_examples "SXP to SPARQL" do |name, sxp|
  it(name) do
    sse = SPARQL::Algebra.parse(sxp)
    sparql_result = sse.to_sparql
    production = sparql_result.match?(/ASK|SELECT|CONSTRUCT|DESCRIBE/) ? :QueryUnit : :UpdateUnit
    expect(sparql_result).to generate(sxp, resolve_iris: false, production: production, validate: true)
  end
end

describe SPARQL::Algebra::Operator do
  it_behaves_like "SXP to SPARQL", "simple query",
    %{(prefix ((: <http://example/>))
          (bgp (triple :s :p :o)))}

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
          it_behaves_like "SXP to SPARQL", sxp, sxp
        end
      end
    end
  end

  context "Issues" do
    it_behaves_like "SXP to SPARQL", "#39",
      SPARQL.parse(%(
        PREFIX obo: <http://purl.obolibrary.org/obo/>

        SELECT DISTINCT ?enst
        FROM <http://rdf.integbio.jp/dataset/togosite/ensembl>
        WHERE {

          ?enst obo:SO_transcribed_from ?ensg .
        }
        LIMIT 10
        )).to_sxp

    it_behaves_like "SXP to SPARQL", "#40",
      SPARQL.parse(%(
        PREFIX obo: <http://purl.obolibrary.org/obo/>
        PREFIX taxon: <http://identifiers.org/taxonomy/>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX faldo: <http://biohackathon.org/resource/faldo#>
        PREFIX dc: <http://purl.org/dc/elements/1.1/>

        SELECT DISTINCT ?parent ?child ?child_label
        FROM <http://rdf.integbio.jp/dataset/togosite/ensembl>
        WHERE {
          ?enst obo:SO_transcribed_from ?ensg .
          ?ensg a ?parent ;
                obo:RO_0002162 taxon:9606 ;
                faldo:location ?ensg_location ;
                dc:identifier ?child ;
                rdfs:label ?child_label .
          FILTER(CONTAINS(STR(?parent), "terms/ensembl/"))
          BIND(STRBEFORE(STRAFTER(STR(?ensg_location), "GRCh38/"), ":") AS ?chromosome)
          VALUES ?chromosome {
              "1" "2" "3" "4" "5" "6" "7" "8" "9" "10"
              "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22"
              "X" "Y" "MT"
          }
        }
        )).to_sxp do
      before {pending}
    end
  end
end
