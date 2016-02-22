module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `day` operator.
    #
    # @example
    #     (prefix ((: <http://example.org/>))
    #       (project (?s ?x)
    #         (extend ((?x (day ?date)))
    #           (bgp (triple ?s :date ?date)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-day
    class Day < Operator::Unary
      include Evaluatable

      NAME = :day

      ##
      # Returns the day part of `arg` as an integer.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand)
        raise TypeError, "expected an RDF::Literal::DateTime, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::DateTime)
        RDF::Literal(operand.object.day)
      end
    end # Day
  end # Operator
end; end # SPARQL::Algebra
