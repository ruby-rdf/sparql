$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'strscan'

include SPARQL::Algebra

shared_examples "SXP to SPARQL" do |name, sxp, **options|
  it(name) do
    sse = SPARQL::Algebra.parse(sxp)
    sparql_result = sse.to_sparql
    production = sparql_result.match?(/ASK|SELECT|CONSTRUCT|DESCRIBE/) ? :QueryUnit : :UpdateUnit
    expect(sparql_result).to generate(sxp, resolve_iris: false, production: production, validate: true, **options)
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
        while scanner.skip_until(/# @example SPARQL Grammar(.*)$/)
          ctx = scanner.matched.sub(/.*Grammar\s*/, '')
          current = {}
          current[:sparql] = scanner.scan_until(/# @example SSE.*$/).gsub(/^\s*#/, '').sub(/@example SSE.*$/, '')
          current[:sxp]    = scanner.scan_until(/^\s+#\s*$/).gsub(/^\s*#/, '')
          current[:ctx]    = ctx unless ctx.empty?
          (examples[op] ||= []) << current
        end
      end
      examples
    end

    read_examples.each do |op, examples|
      describe "Operator #{op}:" do
        examples.each do |example|
          sxp, sparql, ctx = example[:sxp], example[:sparql], example[:ctx]
          it_behaves_like "SXP to SPARQL", (ctx || ('sxp: ' + sxp)), sxp, logger: "Source:\n#{sparql}"
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

    #   PREFIX obo: <http://purl.obolibrary.org/obo/>
    #   PREFIX taxon: <http://identifiers.org/taxonomy/>
    #   PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    #   PREFIX faldo: <http://biohackathon.org/resource/faldo#>
    #   PREFIX dc: <http://purl.org/dc/elements/1.1/>
    #   
    #   SELECT DISTINCT ?parent ?child ?child_label
    #   FROM <http://rdf.integbio.jp/dataset/togosite/ensembl>
    #   WHERE {
    #     ?enst obo:SO_transcribed_from ?ensg .
    #     ?ensg a ?parent ;
    #           obo:RO_0002162 taxon:9606 ;
    #           faldo:location ?ensg_location ;
    #           dc:identifier ?child ;
    #           rdfs:label ?child_label .
    #     FILTER(CONTAINS(STR(?parent), "terms/ensembl/"))
    #     BIND(STRBEFORE(STRAFTER(STR(?ensg_location), "GRCh38/"), ":") AS ?chromosome)
    #     VALUES ?chromosome {
    #         "1" "2" "3" "4" "5" "6" "7" "8" "9" "10"
    #         "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22"
    #         "X" "Y" "MT"
    #     }
    #   }
    it_behaves_like "SXP to SPARQL", "#40", %{
      (prefix ((obo: <http://purl.obolibrary.org/obo/>)
               (taxon: <http://identifiers.org/taxonomy/>)
               (rdfs: <http://www.w3.org/2000/01/rdf-schema#>)
               (faldo: <http://biohackathon.org/resource/faldo#>)
               (dc: <http://purl.org/dc/elements/1.1/>))
       (dataset (<http://rdf.integbio.jp/dataset/togosite/ensembl>)
        (distinct
         (project (?parent ?child ?child_label)
          (filter (contains (str ?parent) "terms/ensembl/")
           (join
             (extend ((?chromosome (strbefore (strafter (str ?ensg_location) "GRCh38/") ":")))
              (bgp (triple ?enst obo:SO_transcribed_from ?ensg)
               (triple ?ensg a ?parent)
                (triple ?ensg obo:RO_0002162 taxon:9606)
                 (triple ?ensg faldo:location ?ensg_location)
                  (triple ?ensg dc:identifier ?child)
                   (triple ?ensg rdfs:label ?child_label)))
             (table (vars ?chromosome)
              (row (?chromosome "1"))
              (row (?chromosome "2"))
              (row (?chromosome "3"))
              (row (?chromosome "4"))
              (row (?chromosome "5"))
              (row (?chromosome "6"))
              (row (?chromosome "7"))
              (row (?chromosome "8"))
              (row (?chromosome "9"))
              (row (?chromosome "10"))
              (row (?chromosome "11"))
              (row (?chromosome "12"))
              (row (?chromosome "13"))
              (row (?chromosome "14"))
              (row (?chromosome "15"))
              (row (?chromosome "16"))
              (row (?chromosome "17"))
              (row (?chromosome "18"))
              (row (?chromosome "19"))
              (row (?chromosome "20"))
              (row (?chromosome "21"))
              (row (?chromosome "22"))
              (row (?chromosome "X"))
              (row (?chromosome "Y"))
              (row (?chromosome "MT")))))))))
    }
  end
end
