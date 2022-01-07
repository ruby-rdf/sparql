module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `abs` operator.
    #
    # [121] BuiltInCall ::= ... | 'ABS' '(' Expression ')'
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT * WHERE {
    #     ?s :num ?num
    #     FILTER(ABS(?num) >= 2)
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>))
    #    (filter (>= (abs ?num) 2)
    #     (bgp (triple ?s :num ?num))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-abs
    # @see https://www.w3.org/TR/xpath-functions/#func-abs
    class Abs < Operator::Unary
      include Evaluatable

      NAME = [:abs]

      ##
      # Returns the absolute value of `arg`. An error is raised if `arg` is not a numeric value.
      # 
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand, **options)
        case operand
          when RDF::Literal::Numeric then operand.abs
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{operand.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "ABS(#{operands.first.to_sparql(**options)})"
      end
    end # Abs
  end # Operator
end; end # SPARQL::Algebra
