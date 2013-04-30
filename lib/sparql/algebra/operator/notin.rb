module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `in` operator.
    #
    # Used for filters with more than one expression.
    #
    # @example
    #   (ask (filter (notin 2) (bgp)))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-notin
    class NotIn < Operator
      include Evaluatable

      NAME = :in

      ##
      # The NOT IN operator tests whether the RDF term on the left-hand side is not found in the values of list of expressions on the right-hand side. The test is done with "!=" operator, which tests for not the same value, as determined by the operator mapping.
      # 
      # A list of zero terms on the right-hand side is legal.
      # 
      # Errors in comparisons cause the NOT IN expression to raise an error if the RDF term being tested is not found to be in the list elsewhere in the list of terms.
      # 
      # The NOT IN operator is equivalent to the SPARQL expression:
      # 
      #     (lhs != expression1) && (lhs != expression2) && ...
      #
      # NOT IN (...) is equivalent to !(IN (...)).
      # 
      # @example
      #
      #     2 NOT IN (1, 2, 3)	false
      #     2 NOT IN ()	true
      #     2 NOT IN (<http://example/iri>, "str", 2.0)	false
      #     2 NOT IN (1/0, 2)	false
      #     2 NOT IN (2, 1/0)	false
      #     2 NOT IN (3, 1/0)	raises an error
      #
      # @param  [RDF::Query::Solution, #[]] bindings
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if term is not found and any operand raises an error
      def evaluate(bindings = {})
        lhs = operands.shift.evaluate(bindings)
        error_found = false
        found = operands.any? do |op|
          begin
            lhs == op.evaluate(bindings)
          rescue TypeError
            error_found = true
          end
        end
        case
        when found then RDF::Literal::FALSE
        when error_found then raise TypeError
        else RDF::Literal::TRUE
        end
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
