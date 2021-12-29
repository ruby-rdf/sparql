module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `round` operator.
    #
    # Returns the number with no fractional part that is closest to the argument. If there are two such numbers, then the one that is closest to positive infinity is returned. An error is raised if `arg` is not a numeric value.
    # 
    # [121] BuiltInCall ::= ... 'ROUND' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   SELECT ?s ?num (ROUND(?num) AS ?round) WHERE {
    #    ?s :num ?num
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>)
    #     (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (project (?s ?num ?round)
    #     (extend ((?round (round ?num)))
    #      (bgp (triple ?s :num ?num)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-round
    # @see https://www.w3.org/TR/xpath-functions/#func-round
    class Round < Operator::Unary
      include Evaluatable

      NAME = [:round]

      ##
      # Returns the number with no fractional part that is closest to the argument. If there are two such numbers, then the one that is closest to positive infinity is returned. An error is raised if arg is not a numeric value.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand, **options)
        case operand
          when RDF::Literal::Numeric then operand.round
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{operand.inspect}"
        end
      end
    end # Round

    ##
    #
    # Returns a partial SPARQL grammar for this operator.
    #
    # @return [String]
    def to_sparql(**options)
      "ROUND(#{operands.to_sparql(**options)})"
    end
  end # Operator
end; end # SPARQL::Algebra
