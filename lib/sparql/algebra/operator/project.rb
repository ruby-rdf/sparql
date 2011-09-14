module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `order` operator.
    #
    # @example
    #   (select (?v)
    #     (project (?v)
    #       (filter (= ?v 2)
    #         (bgp (triple ?s <http://example/p> ?v)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#modProjection
    class Project < Operator::Binary
      include Query
      
      NAME = [:project]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Reduces the result set to the variables listed in the first operand
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        @solutions = operands.last.
          execute(queryable, options.merge(:depth => options[:depth].to_i + 1)).
          project(*(operands.first))
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
    end # Project
  end # Operator
end; end # SPARQL::Algebra
