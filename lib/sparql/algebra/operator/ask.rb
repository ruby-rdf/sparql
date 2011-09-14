module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `ask` operator.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (ask
    #       (bgp (triple :x :p ?x))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#ask
    class Ask < Operator::Unary
      include Query
      
      NAME = [:ask]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Returns true if any solutions are found, false otherwise.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Literal::Boolean]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        debug("Ask #{operands.first}", options)
        boolean(!operands.last.
          execute(queryable, options.merge(:depth => options[:depth].to_i + 1)).
          empty?)
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
    end # Ask
  end # Operator
end; end # SPARQL::Algebra
