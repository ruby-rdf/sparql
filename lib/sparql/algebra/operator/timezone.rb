module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `timezone` operator.
    #
    # Returns the timezone part of `arg` as an xsd:dayTimeDuration. Raises an error if there is no timezone.
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
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand)
        raise TypeError, "expected an RDF::Literal::DateTime, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::DateTime)
        raise TypeError, "literal has no timezone" unless res = operand.timezone
        res
      end
    end # Timezone
  end # Operator
end; end # SPARQL::Algebra
