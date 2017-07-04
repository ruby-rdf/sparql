require 'linkeddata'
require 'pp'
ttl = %(
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix simc: <http://www.ifi.uio.no/INF3580/simpson-collection#> .
@prefix sim: <http://www.ifi.uio.no/INF3580/simpsons#>.

simc:Collection a rdf:List.
simc:Collection rdf:first sim:Homer.
simc:Collection rdf:rest simc:c1.
simc:c1 rdf:first sim:Marge.
simc:c1 rdf:rest simc:c2.
simc:c2 rdf:first sim:Bart.
simc:c2 rdf:rest simc:c3.
simc:c3 rdf:first sim:Maggie.
simc:c3 rdf:rest simc:c4.
simc:c4 rdf:first sim:Lisa.
simc:c4 rdf:rest rdf:nil.
)
rep = RDF::Repository.new
RDF::Turtle::Reader.new(ttl) do |reader|
  rep << reader
end

query = %{
  PREFIX simc: <http://www.ifi.uio.no/INF3580/simpson-collection#>
  PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

  SELECT ?r ?f WHERE {
    simc:Collection rdf:rest* ?r .
    ?r rdf:first ?f
  }
}
pp SPARQL.execute(query, rep)
