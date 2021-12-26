module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric unary `-` (negation) operator.
    #
    # [118] UnaryExpression ::=	... | '-' PrimaryExpression 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s WHERE {
    #     ?s :p ?o .
    #     FILTER(-?o = -2) .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>))
    #    (project (?s)
    #     (filter (= (- ?o) -2)
    #      (bgp (triple ?s :p ?o)))))
    #
    # @see https://www.w3.org/TR/xpath-functions/#func-numeric-unary-minus
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
      def apply(term, **options)
        case term
          when RDF::Literal::Numeric then -term
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{term.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(-#{operands.to_sparql(**options)})"
      end
    end # Negate
  end # Operator
end; end # SPARQL::Algebra
