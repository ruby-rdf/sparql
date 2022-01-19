module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric `multiply` operator.
    #
    # [117] MultiplicativeExpression::= UnaryExpression ( '*' UnaryExpression | '/' UnaryExpression )*
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s WHERE {
    #     ?s :p ?o .
    #     ?s2 :p ?o2 .
    #     FILTER(?o * ?o2 = 4) .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>))
    #    (project (?s)
    #     (filter (= (* ?o ?o2) 4)
    #      (bgp
    #       (triple ?s :p ?o)
    #       (triple ?s2 :p ?o2)))))
    #
    # @see https://www.w3.org/TR/xpath-functions/#func-numeric-multiply
    class Multiply < Operator::Binary
      include Evaluatable

      NAME = [:*, :multiply]

      ##
      # Returns the arithmetic product of the operands.
      #
      # @param  [RDF::Literal::Numeric] left
      #   a numeric literal
      # @param  [RDF::Literal::Numeric] right
      #   a numeric literal
      # @return [RDF::Literal::Numeric]
      # @raise  [TypeError] if either operand is not a numeric literal
      def apply(left, right, **options)
        case
          when left.is_a?(RDF::Literal::Numeric) && right.is_a?(RDF::Literal::Numeric)
            left * right
          else raise TypeError, "expected two RDF::Literal::Numeric operands, but got #{left.inspect} and #{right.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(#{operands.first.to_sparql(**options)} * #{operands.last.to_sparql(**options)})"
      end
    end # Multiply
  end # Operator
end; end # SPARQL::Algebra
