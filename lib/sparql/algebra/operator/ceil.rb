module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `ceil` operator.
    #
    # @example
    #   (ceil ?x)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-ceil
    # @see http://www.w3.org/TR/xpath-functions/#func-ceil
    class Ceil < Operator::Unary
      include Evaluatable

      NAME = [:ceil]

      ##
      # Returns the smallest (closest to negative infinity) number with no fractional part that is not less than the value of `arg`. An error is raised if `arg` is not a numeric value.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand)
        case operand
          when RDF::Literal::Numeric then operand.ceil
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{operand.inspect}"
        end
      end
    end # Ceil
  end # Operator
end; end # SPARQL::Algebra
