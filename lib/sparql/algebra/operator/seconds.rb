module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `seconds` operator.
    #
    # Returns the seconds part of the lexical form of `arg`.
    #
    # [121] BuiltInCall ::= ... | 'SECONDS' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s (SECONDS(?date) AS ?x) WHERE {
    #     ?s :date ?date
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?x)
    #     (extend ((?x (seconds ?date)))
    #      (bgp (triple ?s :date ?date)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-seconds
    class Seconds < Operator::Unary
      include Evaluatable

      NAME = :seconds

      ##
      # Returns the seconds part of arg as an integer.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal::Temporal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Literal::Temporal, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::Temporal)
        RDF::Literal(operand.object.second)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "SECONDS(#{operands.last.to_sparql(**options)})"
      end
    end # Seconds
  end # Operator
end; end # SPARQL::Algebra
