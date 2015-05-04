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
      # @overload self.new(*patterns)
      #   @param [Array<RDF::Query::Pattern>] patterns
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query]
      def self.new(*patterns, &block)
        RDF::Query.new(*(patterns + [{context: false}]), &block)
      end
    end # BGP
  end # Operator
end; end # SPARQL::Algebra
