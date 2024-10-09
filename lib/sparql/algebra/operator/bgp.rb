module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `bgp` operator.
    #
    # Query with `graph_name` set to false.
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example/>
    #   SELECT * { ?s ?p ?o }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #     (bgp (triple ?s ?p ?o)))
    #
    # @example SPARQL Grammar (sparql-star)
    #   PREFIX : <http://example.com/ns#>
    #   SELECT * {<< :a :b :c ~ :r >> :p1 :o1.}
    #
    # @example SSE (sparql-star)
    #   (prefix
    #    ((: <http://example.com/ns#>))
    #    (bgp
    #     (triple :r <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
    #      (qtriple :a :b :c))
    #     (triple :r :p1 :o1)))
    #
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    class BGP < Operator
      NAME = [:bgp]
      ##
      # A `graph` is an RDF::Query with a graph_name.
      #
      # @overload self.new(*patterns)
      #   @param [Array<RDF::Query::Pattern>] patterns
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query]
      def self.new(*patterns, **options, &block)
        RDF::Query.new(*patterns, graph_name: false, &block)
      end
    end # BGP
  end # Operator
end; end # SPARQL::Algebra
