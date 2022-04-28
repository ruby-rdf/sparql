module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `tz` operator.
    #
    # Returns the timezone part of `arg` as a simple literal. Returns the empty string if there is no timezone.
    #
    # [121] BuiltInCall ::= ... | 'TZ' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s (TZ(?date) AS ?x) WHERE {
    #     ?s :date ?date
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?x)
    #     (extend ((?x (tz ?date)))
    #      (bgp (triple ?s :date ?date)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-tz
    class TZ < Operator::Unary
      include Evaluatable

      NAME = :tz

      ##
      # Returns the timezone part of arg as a simple literal. Returns the empty string if there is no timezone.
      #
      # @param  [RDF::Literal::Temporal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Literal::Temporal, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::Temporal)
        operand.tz
      end
      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "TZ(" + operands.to_sparql(**options) + ")"
      end
    end # TZ
  end # Operator
end; end # SPARQL::Algebra
