module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `exprlist` operator.
    #
    # Used for filters with more than one expression.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (project (?v ?w)
    #       (filter (exprlist (= ?v 2) (= ?w 3))
    #         (bgp
    #           (triple ?s :p ?v)
    #           (triple ?s :q ?w)
    #         ))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#evaluation
    class Exprlist < Operator
      include Evaluatable

      NAME = [:exprlist]

      ##
      # Returns `true` if all operands evaluate to `true`.
      #
      # Note that this operator operates on the effective boolean value
      # (EBV) of its operands.
      #
      # @example
      #
      #   (exprlist (= 1 1) (!= 1 0))
      #
      # @param  [RDF::Query::Solution, #[]] bindings
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operands could not be coerced to a boolean literal
      def evaluate(bindings = {})
        res = operands.all? {|op| boolean(op.evaluate(bindings)).true? }
        RDF::Literal(res) # FIXME: error handling
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
    end # Exprlist
  end # Operator
end; end # SPARQL::Algebra
