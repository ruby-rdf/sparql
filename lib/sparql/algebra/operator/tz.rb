module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `tz` operator.
    #
    # Returns the timezone part of `arg` as a simple literal. Returns the empty string if there is no timezone.
    #
    # @example
    #     (prefix ((: <http://example.org/>))
    #       (project (?s ?x)
    #         (extend ((?x (tz ?date)))
    #           (bgp (triple ?s :date ?date)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-tz
    class TZ < Operator::Unary
      include Evaluatable

      NAME = :tz

      ##
      # Returns the timezone part of arg as a simple literal. Returns the empty string if there is no timezone.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand)
        raise TypeError, "expected an RDF::Literal::DateTime, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::DateTime)
        operand.tz
      end
    end # TZ
  end # Operator
end; end # SPARQL::Algebra
