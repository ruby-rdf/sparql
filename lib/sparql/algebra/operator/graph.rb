module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `graph` operator.
    #
    # This is a wrapper to add a `context` to the query.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (graph ?g
    #       (bgp (triple ?s ?p ?o))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
    class Graph < Operator::Binary
      NAME = [:graph]
      ##
      # A `graph` is an RDF::Query with a context.
      #
      # @param [RDF::URI, RDF::Query::Variable] context
      # @param [RDF::Query] bgp
      # @return [RDF::Query]
      def self.new(context, bgp)
        bgp.context = context
        bgp
      end
    end # Graph
  end # Operator
end; end # SPARQL::Algebra
