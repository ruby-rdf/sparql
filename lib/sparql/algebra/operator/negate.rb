module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric unary `-` (negation) operator.
    #
    # @example
    #   (- ?x)
    #   (negate ?x)
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-minus
    class Negate < Operator::Unary
      include Evaluatable

      NAME = [:-, :negate]

      ##
      # Returns the operand with its sign reversed.
      #
      # @param  [RDF::Literal::Numeric] term
      #   a numeric literal
      # @return [RDF::Literal::Numeric]
      # @raise  [TypeError] if the operand is not a numeric literal
      def apply(term)
        case term
          when RDF::Literal::Numeric then -term
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{term.inspect}"
        end
      end
    end # Negate
  end # Operator
end; end # SPARQL::Algebra
