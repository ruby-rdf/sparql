module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `timezone` operator.
    #
    # @example
    #     (prefix ((: <http://example.org/>))
    #       (project (?s ?x)
    #         (extend ((?x (timezone ?date)))
    #           (bgp (triple ?s :date ?date)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-timezone
    class Timezone < Operator::Unary
      include Evaluatable

      NAME = :timezone

      ##
      # Returns the timezone part of arg as an xsd:dayTimeDuration. Raises an error if there is no timezone.
      #
      # This function corresponds to fn:timezone-from-dateTime except for the treatment of literals with no timezone.
      #
      # Note: RDF::Literal::DateTime cannot distinguish no zimezone from Zulu, as the core Ruby DateTime class does not distinguish this.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand)
        raise TypeError, "expected an RDF::Literal::DateTime, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::DateTime)
        plus_minus, hour, min = operand.object.zone.match(/^([+-])?(\d+):(\d+)?$/)[1,3]
        plus_minus = nil unless plus_minus == "-"
        hour = hour.to_i
        min = min.to_i
        res = case
        when hour + min == 0 then "PT0S"
        else "#{plus_minus}PT#{hour}H#{"#{min}M" if min > 0}"
        end
        RDF::Literal(res, :datatype => RDF::XSD.dayTimeDuration)
      end
    end # Timezone
  end # Operator
end; end # SPARQL::Algebra
