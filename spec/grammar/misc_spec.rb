$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

# Misclaneous test cases, based on observed or reported problems
describe SPARQL::Grammar do
  describe "misclaneous" do
    {
      "rdfa 0085" => {
        graphs: { default: { format: :ttl, data: %q(
            <http://www.example.org/#somebody> <http://xmlns.com/foaf/0.1/knows> _:a .
            _:a <http://xmlns.com/foaf/0.1/knows> <http://www.ivan-herman.org/Ivan_Herman> .
            _:a <http://xmlns.com/foaf/0.1/knows> <http://www.w3.org/People/Berners-Lee/card#i> .
            _:a <http://xmlns.com/foaf/0.1/knows> <http://danbri.org/foaf.rdf#danbri> .
          )
        }},
        query: %q(
          ASK WHERE {
              <http://www.example.org/#somebody> <http://xmlns.com/foaf/0.1/knows> _:a .
            _:a <http://xmlns.com/foaf/0.1/knows> <http://www.ivan-herman.org/Ivan_Herman> ,
              <http://www.w3.org/People/Berners-Lee/card#i> ,
              <http://danbri.org/foaf.rdf#danbri> .
          }
        )
      }
    }.each do |test, options|
      it "returns true for #{test}" do
        result = sparql_query(options.merge(repository: "sparql-spec", form: :ask, to_hash: false))
        expect(result).to eq RDF::Literal::TRUE
      end
    end

    {
      "issue 25" => {
        query: %(
          PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
          PREFIX owl: <http://www.w3.org/2002/07/owl#>

          SELECT ?class (group_concat(DISTINCT ?item;separator=",") as ?keys) WHERE {
            ?class rdf:type owl:Class .
            ?class owl:hasKey ?key .
            ?key rdf:rest*/rdf:first ?item .
          }
          GROUP BY ?class ?key
        ),
        sse: %{
          (project
            (?class ?keys)
            (extend ((?keys ?.0))
              (group (?class ?key)
                ((?.0 (group_concat (separator ",") distinct ?item)))
                (join
                  (bgp (triple ?class <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Class>))
                  (join
                    (bgp (triple ?class <http://www.w3.org/2002/07/owl#hasKey> ?key))
                    (path ?key
                      (seq
                        (path* <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>)
                        <http://www.w3.org/1999/02/22-rdf-syntax-ns#first>
                      )
                      ?item))))))
        }
      },
      "issue 27" => {
        query: %(
          PREFIX simc: <http://www.ifi.uio.no/INF3580/simpson-collection#>
          PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

          SELECT ?r ?f WHERE {
            simc:Collection rdf:rest* ?r .
            ?r rdf:first ?f
          }
        ),
        sse: %{(project (?r ?f)
         (join
          (path <http://www.ifi.uio.no/INF3580/simpson-collection#Collection>
           (path* <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>)
           ?r)
          (bgp (triple ?r <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> ?f))
         )
        )}
      }
    }.each do |test, options|
      it "parses #{test}" do
        expect(options[:query]).to generate(options[:sse], {})
      end
    end
  end
end
