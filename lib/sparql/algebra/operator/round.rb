module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `round` operator.
    #
    # Returns the number with no fractional part that is closest to the argument. If there are two such numbers, then the one that is closest to positive infinity is returned. An error is raised if `arg` is not a numeric value.
    # 
    # @example
    #   (round ?x)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-round
    # @see http://www.w3.org/TR/xpath-functions/#func-round
    class Round < Operator::Unary
      include Evaluatable

      NAME = [:round]

      ##
      # Returns the number with no fractional part that is closest to the argument. If there are two such numbers, then the one that is closest to positive infinity is returned. An error is raised if arg is not a numeric value.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand)
        case operand
          when RDF::Literal::Numeric then operand.round
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{operand.inspect}"
        end
      end
    end # Round
  end # Operator
end; end # SPARQL::Algebra
