module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric binary/unary `+` operator.
    #
    # @example
    #   (+ ?x ?y)
    #   (plus ?x ?y)
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-plus
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-add
    class Plus < Operator::Unary
      include Evaluatable

      NAME = [:+, :plus]

      ##
      # Returns the arithmetic sum of the operands, unless there is no `right`.
      #
      # @param  [RDF::Literal::Numeric] left
      #   a numeric literal
      # @param  [RDF::Literal::Numeric] right
      #   a numeric literal
      # @return [RDF::Literal::Numeric]
      # @raise  [TypeError] if either operand is not a numeric literal
      def apply(left, right = nil)
        case
        when left.is_a?(RDF::Literal::Numeric) && right.is_a?(RDF::Literal::Numeric)
          left + right
        when left.is_a?(RDF::Literal::Numeric) && right.nil?
          left
        else raise TypeError, "expected two RDF::Literal::Numeric operands, but got #{left.inspect} and #{right.inspect}"
        end
      end
    end # Plus
  end # Operator
end; end # SPARQL::Algebra
