module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `year` operator.
    #
    # Returns the year part of `arg` as an integer.
    #
    # [121] BuiltInCall ::= ... | 'YEAR' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s (YEAR(?date) AS ?x) WHERE {
    #     ?s :date ?date
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?x)
    #     (extend ((?x (year ?date)))
    #      (bgp (triple ?s :date ?date)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-year
    class Year < Operator::Unary
      include Evaluatable

      NAME = :year

      ##
      # Returns the year part of arg as an integer.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal::Temporal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Literal::Temporal, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::Temporal)
        RDF::Literal(operand.object.year)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "YEAR(#{operands.last.to_sparql(**options)})"
      end
    end # Year
  end # Operator
end; end # SPARQL::Algebra
