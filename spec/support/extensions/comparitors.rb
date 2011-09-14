require 'rdf/isomorphic'

module RDF::Isomorphic
  alias_method :==, :isomorphic_with?
end
