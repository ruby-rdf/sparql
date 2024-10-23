$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

# Misclaneous test cases, based on observed or reported problems
describe SPARQL::Grammar do
  let(:logger) {RDF::Spec.logger.tap {|l| l.level = Logger::INFO}}

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
        result = sparql_query(repository: "sparql-spec",
                              form: :ask,
                              all_vars: true,
                              to_hash: false,
                              logger: logger, **options)
        expect(result).to produce(RDF::Literal::TRUE, logger: logger)
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
            (extend ((?keys ??.0))
              (group (?class ?key)
                ((??.0 (group_concat distinct (separator ",") ?item)))
                (sequence
                  (bgp
                   (triple ?class <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.w3.org/2002/07/owl#Class>)
                   (triple ?class <http://www.w3.org/2002/07/owl#hasKey> ?key))
                  (path ?key
                    (seq
                      (path* <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>)
                      <http://www.w3.org/1999/02/22-rdf-syntax-ns#first>
                    )
                    ?item)))))
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
         (sequence
          (path <http://www.ifi.uio.no/INF3580/simpson-collection#Collection>
           (path* <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>)
           ?r)
          (bgp (triple ?r <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> ?f))
         )
        )}
      },
      "issue 33" => {
        query: %(
          CONSTRUCT {
            ?uri <http://prop3> ?anotherURI .
          }
          WHERE
          {
            ?uri a ?type ;
              <http://prop1> / <http://prop2> ?anotherURI
          }
        ),
        sse: %{(construct
          ((triple ?uri <http://prop3> ?anotherURI))
          (sequence
           (bgp (triple ?uri a ?type)) 
           (path ?uri (seq <http://prop1> <http://prop2>) ?anotherURI)
          )
        )}
      },
      "pp bgp sequence" => {
        query: %(
          PREFIX : <http://example/>
          SELECT * {?a :b/:b _:o . _:o :c :d .}
        ),
        sse: %{(sequence
           (path ?a (seq <http://example/b> <http://example/b>) ??o)
           (bgp (triple ??o <http://example/c> <http://example/d>))
        )}
      },
      "issue 42" => {
        query: %(
          PREFIX : <http://example/>
          SELECT * {?a :b/:b [ :c :d] .}
        ),
        sse: %{(sequence
           (path ?a (seq <http://example/b> <http://example/b>) ??0)
           (bgp (triple ??0 <http://example/c> <http://example/d>))
        )}
      },
      "issue 46" => {
        query: %(
          PREFIX ex: <http://example.org/>

          SELECT ?ev (MIN(?a) as ?a_min) (MIN(?b) as ?b_min)
          WHERE {?ev ex:a ?a ; ex:b ?b . }
          GROUP BY ?ev
        ),
        sse: %{(project (?ev ?a_min ?b_min)
                (extend ((?a_min ??.0) (?b_min ??.1))
                 (group (?ev) ((??.0 (min ?a)) (??.1 (min ?b)))
                  (bgp
                   (triple ?ev <http://example.org/a> ?a)
                   (triple ?ev <http://example.org/b> ?b)))))
        }
      },
      "dawg-optional-filter-005-not-simplified" => {
        query: %(
          # Double curly braces do NOT get simplified to single curly braces early on, before filters are scoped
          PREFIX  dc: <http://purl.org/dc/elements/1.1/>
          PREFIX  x: <http://example.org/ns#>
          SELECT  ?title ?price
          WHERE
              { ?book dc:title ?title . 
                OPTIONAL
                  {
                    { 
                      ?book x:price ?price . 
                      FILTER (?title = "TITLE 2") .
                    }
                  } .
              }
        ),
        sse: %{(prefix ((dc: <http://purl.org/dc/elements/1.1/>) (x: <http://example.org/ns#>))
                (project (?title ?price)
                 (leftjoin
                  (bgp (triple ?book dc:title ?title))
                  (filter (= ?title "TITLE 2")
                    (bgp (triple ?book x:price ?price))))))
             }
      }
    }.each do |test, options|
      it "parses #{test}" do
        expect(options[:query]).to generate(options[:sse], logger: logger)
      end
    end
  end

  describe "property path errors" do
    {
      "{}" => {
        query: %(SELECT * WHERE {:a :b{,} :c}),
        exception: /expect property range to have integral elements/
      },
      "{,}" => {
        query: %(SELECT * WHERE {:a :b{,} :c}),
        exception: /expect property range to have integral elements/
      },
      "{2,1}" => {
        query: %(SELECT * WHERE {:a :b{2,1} :c}),
        exception: /expect min <= max/
      },
    }.each do |test, options|
      it "#{test}" do
        expect {
          sparql_query(logger: logger, **options)
        }.to raise_error(options[:exception])
      end
    end
  end
end
