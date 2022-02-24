module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `day` operator.
    #
    # [121] BuiltInCall ::= ... | 'DAY' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s (DAY(?date) AS ?x) WHERE {
    #     ?s :date ?date
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?x)
    #     (extend ((?x (day ?date)))
    #      (bgp (triple ?s :date ?date)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-day
    class Day < Operator::Unary
      include Evaluatable

      NAME = :day

      ##
      # Returns the day part of `arg` as an integer.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal::Temporal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Literal::Temporal, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::Temporal)
        RDF::Literal(operand.object.day)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "DAY(#{operands.last.to_sparql(**options)})"
      end
    end # Day
  end # Operator
end; end # SPARQL::Algebra
