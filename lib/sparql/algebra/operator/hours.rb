module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `hours` operator.
    #
    # [121] BuiltInCall ::= ... | 'HOURS' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s (HOURS(?date) AS ?x) WHERE {
    #     ?s :date ?date
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?x)
    #     (extend ((?x (hours ?date)))
    #      (bgp (triple ?s :date ?date)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-hours
    class Hours < Operator::Unary
      include Evaluatable

      NAME = :hours

      ##
      # Returns the hours part of `arg` as an integer. The value is as given in the lexical form of the XSD dateTime.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal::Temporal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Literal::Temporal, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::Temporal)
        RDF::Literal(operand.object.hour)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "HOURS(#{operands.last.to_sparql(**options)})"
      end
    end # Hours
  end # Operator
end; end # SPARQL::Algebra
