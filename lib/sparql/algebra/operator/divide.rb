module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric `divide` operator.
    #
    # @example
    #   (/ 4 2)
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-divide
    class Divide < Operator::Binary
      include Evaluatable

      NAME = [:'/', :divide]

      ##
      # Returns the arithmetic quotient of the operands.
      #
      # @param  [RDF::Literal::Numeric] left
      #   a numeric literal
      # @param  [RDF::Literal::Numeric] right
      #   a numeric literal
      # @return [RDF::Literal::Numeric]
      # @raise  [TypeError] if either operand is not a numeric literal
      def apply(left, right)
        case
          when left.is_a?(RDF::Literal::Numeric) && right.is_a?(RDF::Literal::Numeric)
            # For xsd:decimal and xsd:integer operands, if the divisor is
            # (positive or negative) zero, an error is raised.
            raise ZeroDivisionError, "divided by #{right}" if left.is_a?(RDF::Literal::Decimal) && right.zero?

            # As a special case, if the types of both operands are
            # xsd:integer, then the return type is xsd:decimal.
            if left.is_a?(RDF::Literal::Integer) && right.is_a?(RDF::Literal::Integer)
              RDF::Literal(left.to_d / right.to_d)
            else
              left / right
            end
          else raise TypeError, "expected two RDF::Literal::Numeric operands, but got #{left.inspect} and #{right.inspect}"
        end
      end
    end # Divide
  end # Operator
end; end # SPARQL::Algebra
