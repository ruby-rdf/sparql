module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric unary `+` operator.
    #
    # @example
    #   (+ ?x ?y)
    #   (plus ?x ?y)
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-plus
    class Plus < Operator::Unary
      include Evaluatable

      NAME = [:+, :plus]

      ##
      # Returns the operand with its sign unchanged.
      #
      # @param  [RDF::Literal::Numeric] numeric
      #   a numeric literal
      # @return [RDF::Literal::Numeric]
      # @raise  [TypeError] if the operand is not a numeric literal
      def apply(term)
        case term
          when RDF::Literal::Numeric then term
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{term.inspect}"
        end
      end
    end # Plus
  end # Operator
end; end # SPARQL::Algebra
