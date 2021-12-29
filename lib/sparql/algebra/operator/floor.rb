module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `floor` operator.
    #
    # [121] BuiltInCall ::= ... 'FLOOR' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   SELECT ?s ?num (FLOOR(?num) AS ?floor) WHERE {
    #    ?s :num ?num
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>)
    #     (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (project (?s ?num ?floor)
    #     (extend ((?floor (floor ?num)))
    #      (bgp (triple ?s :num ?num)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-floor
    # @see https://www.w3.org/TR/xpath-functions/#func-floor
    class Floor < Operator::Unary
      include Evaluatable

      NAME = [:floor]

      ##
      # Returns the largest (closest to positive infinity) number with no fractional part that is not greater than the value of `arg`. An error is raised if `arg` is not a numeric value.
      #
      # If type of $arg is one of the four numeric types xs:float, xs:double, xs:decimal or xs:integer the type of the result is the same as the type of $arg. If the type of $arg is a type derived from one of the numeric types, the result is an instance of the base numeric type.
      #
      # For float and double arguments, if the argument is positive zero, then positive zero is returned. If the argument is negative zero, then negative zero is returned.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand, **options)
        case operand
          when RDF::Literal::Numeric then operand.floor
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{operand.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "FLOOR(#{operands.to_sparql(**options)})"
      end
    end # Floor
  end # Operator
end; end # SPARQL::Algebra
