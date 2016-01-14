module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `seconds` operator.
    #
    # Returns the seconds part of the lexical form of `arg`.
    #
    # @example
    #     (prefix ((: <http://example.org/>))
    #       (project (?s ?x)
    #         (extend ((?x (seconds ?date)))
    #           (bgp (triple ?s :date ?date)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-seconds
    class Seconds < Operator::Unary
      include Evaluatable

      NAME = :seconds

      ##
      # Returns the seconds part of arg as an integer.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand)
        raise TypeError, "expected an RDF::Literal::DateTime, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::DateTime)
        RDF::Literal(operand.object.second)
      end
    end # Seconds
  end # Operator
end; end # SPARQL::Algebra
