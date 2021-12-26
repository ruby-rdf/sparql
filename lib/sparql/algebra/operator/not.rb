module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `not` operator.
    #
    # [118] UnaryExpression ::=	... | '!' PrimaryExpression 
    #
    # @example SPARQL Grammar
    #   PREFIX  : <http://example.org/ns#>
    #   SELECT  ?a
    #   WHERE {
    #     ?a :p ?v . 
    #     FILTER ( ! ?v ) .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/ns#>))
    #    (project (?a)
    #     (filter (! ?v)
    #      (bgp (triple ?a :p ?v)))))
    #
    # @see https://www.w3.org/TR/xpath-functions/#func-not
    class Not < Operator::Unary
      include Evaluatable

      NAME = [:'!', :not]

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
      def apply(operand, **options)
        case bool = boolean(operand)
          when RDF::Literal::Boolean
            RDF::Literal(bool.false?)
          else super
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(!" + operands.first.to_sparql(**options) + ")"
      end
    end # Not
  end # Operator
end; end # SPARQL::Algebra
