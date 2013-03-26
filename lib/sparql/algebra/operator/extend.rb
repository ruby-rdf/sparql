module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Bind `extend` operator.
    #
    # @example
    #   (select (?z)
    #     (project (?z)
    #       (extend ((?z (+ ?o 10)))
    #         (bgp (triple ?s <http://example/p> ?o)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#evaluation
    class Extend < Operator::Binary
      include Query
      
      NAME = [:extend]

      ##
      # FIXME
      def execute(queryable, options = {})
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Return optimized query
      #
      # @return FIXME
      def optimize
        operands = operands.map(&:optimize)
      end
    end # Filter
  end # Operator
end; end # SPARQL::Algebra
