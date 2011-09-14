module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `bgp` operator.
    #
    # Query with `context` set to false.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (bgp (triple ?s ?p ?o)))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
    class BGP < Operator
      NAME = [:bgp]
      ##
      # A `graph` is an RDF::Query with a context.
      #
      # @param [RDF::URI, RDF::Query::Variable] context
      # @param [RDF::Query] bgp
      # @return [RDF::Query]
      def self.new(*patterns)
        RDF::Query.new(*patterns, :context => false)
      end
    end # BGP
  end # Operator
end; end # SPARQL::Algebra
