module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric unary `-` (negation) operator.
    #
    # @example
    #   (- ?x)
    #   (minus ?x)
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-minus
    class Minus < Operator::Unary
      include Evaluatable

      NAME = [:-, :minus]

      ##
      # Returns the operand with its sign reversed.
      #
      # @param  [RDF::Literal::Numeric] numeric
      #   a numeric literal
      # @return [RDF::Literal::Numeric]
      # @raise  [TypeError] if the operand is not a numeric literal
      def apply(term)
        case term
          when RDF::Literal::Numeric then -term
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{term.inspect}"
        end
      end
    end # Minus
  end # Operator
end; end # SPARQL::Algebra
