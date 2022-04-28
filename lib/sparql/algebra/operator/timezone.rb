module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `timezone` operator.
    #
    # Returns the timezone part of `arg` as an xsd:dayTimeDuration. Raises an error if there is no timezone.
    #
    # [121] BuiltInCall ::= ... | 'TIMEZONE' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s (TIMEZONE(?date) AS ?x) WHERE {
    #     ?s :date ?date
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?x)
    #     (extend ((?x (timezone ?date)))
    #      (bgp (triple ?s :date ?date)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-timezone
    class Timezone < Operator::Unary
      include Evaluatable

      NAME = :timezone

      ##
      # Returns the timezone part of arg as an xsd:dayTimeDuration. Raises an error if there is no timezone.
      #
      # This function corresponds to fn:timezone-from-dateTime except for the treatment of literals with no timezone.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal::Temporal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Literal::Temporal, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::Temporal)
        raise TypeError, "literal has no timezone" unless res = operand.timezone
        res
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "TIMEZONE(" + operands.to_sparql(**options) + ")"
      end
    end # Timezone
  end # Operator
end; end # SPARQL::Algebra
