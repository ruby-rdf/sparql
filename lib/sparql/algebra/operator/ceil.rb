module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `ceil` operator.
    #
    # [121] BuiltInCall ::= ... 'CEIL' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   SELECT ?s ?num (CEIL(?num) AS ?ceil) WHERE {
    #    ?s :num ?num
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>)
    #     (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (project (?s ?num ?ceil)
    #     (extend ((?ceil (ceil ?num)))
    #      (bgp (triple ?s :num ?num)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-ceil
    # @see https://www.w3.org/TR/xpath-functions/#func-ceil
    class Ceil < Operator::Unary
      include Evaluatable

      NAME = [:ceil]

      ##
      # Returns the smallest (closest to negative infinity) number with no fractional part that is not less than the value of `arg`. An error is raised if `arg` is not a numeric value.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand, **options)
        case operand
          when RDF::Literal::Numeric then operand.ceil
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{operand.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "CEIL(#{operands.to_sparql(**options)})"
      end
    end # Ceil
  end # Operator
end; end # SPARQL::Algebra
