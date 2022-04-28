module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL numeric binary/unary `+` operator.
    #
    # [118] UnaryExpression ::=	... | '+' PrimaryExpression 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s WHERE {
    #     ?s :p ?o .
    #     FILTER(-?o = +3) .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>))
    #    (project (?s)
    #     (filter (= (- ?o) +3)
    #      (bgp (triple ?s :p ?o)))))
    #
    # [116] AdditiveExpression ::=	MultiplicativeExpression ( '+' MultiplicativeExpression )?
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s WHERE {
    #     ?s :p ?o .
    #     ?s2 :p ?o2 .
    #     FILTER(?o + ?o2 = 3) .
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s)
    #     (filter (= (+ ?o ?o2) 3)
    #      (bgp
    #       (triple ?s :p ?o)
    #       (triple ?s2 :p ?o2)))))
    #
    # @see https://www.w3.org/TR/xpath-functions/#func-numeric-unary-plus
    # @see https://www.w3.org/TR/xpath-functions/#func-numeric-add
    class Plus < Operator
      include Evaluatable

      NAME = [:+, :plus]

      ##
      # Returns the arithmetic sum of the operands, unless there is no `right`.
      #
      # @param  [RDF::Literal::Numeric, RDF::Literal::Temporal] left
      #   a numeric literal
      # @param  [RDF::Literal::Numeric, RDF::Literal::Duration] right
      #   a numeric literal
      # @return [RDF::Literal::Numeric, RDF::Literal::Temporal]
      # @raise  [TypeError] if either operand is neither a numeric nor a temporal literal
      def apply(left, right = nil, **options)
        case
        when left.is_a?(RDF::Literal::Numeric) && right.is_a?(RDF::Literal::Numeric)
          left + right
        when left.is_a?(RDF::Literal::Numeric) && right.nil?
          left
        when left.is_a?(RDF::Literal::Temporal) && right.is_a?(RDF::Literal::Duration)
          left + right
        else raise TypeError, "expected two RDF::Literal::Numeric operands or a Temporal and a Duration, but got #{left.inspect} and #{right.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(#{operands.first.to_sparql(**options)} + #{operands.last.to_sparql(**options)})"
      end
    end # Plus
  end # Operator
end; end # SPARQL::Algebra
