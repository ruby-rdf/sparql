module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `adjust` operator.
    #
    # [121] BuiltInCall ::= ... | 'ADJUST' '(' Expression ',' Expression ')'
    #
    # @example SPARQL Grammar
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   SELECT ?id (ADJUST(?d, ?tz) AS ?adjusted) WHERE {
    #     VALUES (?id ?tz ?d) {
    #       (1 "-PT10H"^^xsd:dayTimeDuration "2002-03-07"^^xsd:date)
    #     }
    #   }
    #
    # @example SSE
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (project (?id ?adjusted)
    #     (extend ((?adjusted (adjust ?d ?tz)))
    #      (table (vars ?id ?tz ?d)
    #       (row
    #        (?id 1)
    #        (?tz "-PT10H"^^xsd:dayTimeDuration)
    #        (?d "2002-03-07"^^xsd:date))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-abs
    # @see https://www.w3.org/TR/xpath-functions/#func-abs
    class Adjust < Operator::Binary
      include Evaluatable

      NAME = [:adjust]

      ##
      # Returns the first operand adjusted by the dayTimeDuration of the second operand
      # 
      # @param  [RDF::Literal::Temporal] operand
      #   the operand
      # @param  [RDF::Literal, String] duration
      #   the dayTimeDuration or an empty string.
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand, duration, **options)
        case operand
        when RDF::Literal::Temporal
          case duration
          when RDF::Literal::DayTimeDuration
            operand.adjust_to_timezone(duration)
          when RDF::Literal
            raise TypeError, "expected second operand to be an empty literal, but got #{duration.inspect}" unless duration.to_s.empty?
            operand.adjust_to_timezone(nil)
          else
            raise TypeError, "expected second operand to be an RDF::Literal::DayTimeDuration, but got #{duration.inspect}"
          end
        else
          raise TypeError, "expected first operand to be an RDF::Literal::Temporal, but got #{operand.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "ADJUST(#{operands.to_sparql(delimiter: ', ', **options)})"
      end
    end # Abs
  end # Operator
end; end # SPARQL::Algebra
