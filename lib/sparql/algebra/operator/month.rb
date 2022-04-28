module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `month` operator.
    #
    # Returns the month part of `arg` as an integer.
    #
    # [121] BuiltInCall ::= ... | 'MONTH' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s (MONTH(?date) AS ?x) WHERE {
    #     ?s :date ?date
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?x)
    #     (extend ((?x (month ?date)))
    #      (bgp (triple ?s :date ?date)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-month
    class Month < Operator::Unary
      include Evaluatable

      NAME = :month

      ##
      # Returns the month part of arg as an integer.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal::Temporal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Literal::Temporal, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::Temporal)
        RDF::Literal(operand.object.month)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "MONTH(#{operands.last.to_sparql(**options)})"
      end
    end # Month
  end # Operator
end; end # SPARQL::Algebra
