module SPARQL; module Algebra
  class Operator
    include Evaluatable

    ##
    # The SPARQL numeric `add` operator.
    #
    # @example
    #   (+ 1 ?x)
    #   (add 1 ?x)
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-add
    class Add < Operator::Binary
      NAME = [:+, :add]

      ##
      # Returns the arithmetic sum of the operands.
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
            left + right
          else raise TypeError, "expected two RDF::Literal::Numeric operands, but got #{left.inspect} and #{right.inspect}"
        end
      end
    end # Add
  end # Operator
end; end # SPARQL::Algebra
