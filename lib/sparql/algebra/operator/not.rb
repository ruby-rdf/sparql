module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `not` operator.
    #
    # @example
    #   (! ?x ?y)
    #   (not ?x ?y)
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-not
    class Not < Operator::Unary
      include Evaluatable

      NAME = [:not, :'!']

      ##
      # Returns the logical `NOT` (inverse) of the operand.
      #
      # Note that this operator operates on the effective boolean value
      # (EBV) of its operand.
      #
      # @param  [RDF::Literal::Boolean] operand
      #   the operand
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand could not be coerced to a boolean literal
      def apply(operand)
        case bool = boolean(operand)
          when RDF::Literal::Boolean
            RDF::Literal(bool.false?)
          else super
        end
      end
    end # Not
  end # Operator
end; end # SPARQL::Algebra
