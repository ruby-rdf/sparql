module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric `subtract` operator.
    #   (- ?x ?y)
    #   (subtract ?x ?y)
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-subtract
    class Subtract < Operator::Binary
      include Evaluatable

      NAME = [:-, :subtract]

      ##
      # Returns the arithmetic difference of the operands.
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
            left - right
          else raise TypeError, "expected two RDF::Literal::Numeric operands, but got #{left.inspect} and #{right.inspect}"
        end
      end
    end # Subtract
  end # Operator
end; end # SPARQL::Algebra
