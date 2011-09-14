module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `distinct` operator.
    #
    # @example
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example/>))
    #     (distinct
    #       (project (?v)
    #         (bgp (triple ?x ?p ?v)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
    class Distinct < Operator::Unary
      include Query
      
      NAME = [:distinct]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Removes duplicate solutions from the solution set.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        debug("Distinct", options)
        @solutions = operands.last.execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
        debug("=>(before) #{@solutions.inspect}", options)
        @solutions = @solutions.distinct
        debug("=>(after) #{@solutions.inspect}", options)
        @solutions
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Return optimized query
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        operands = operands.map(&:optimize)
      end
    end # Distinct
  end # Operator
end; end # SPARQL::Algebra
