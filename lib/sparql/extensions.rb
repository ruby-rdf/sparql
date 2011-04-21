require 'rdf'
require 'sparql/results'

##
# Extensions for `RDF::Query::Solutions`.
class RDF::Query::Solutions
  include SPARQL::Results
end