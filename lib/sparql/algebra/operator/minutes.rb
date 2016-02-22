module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `minutes` operator.
    #
    # Returns the minutes part of the lexical form of `arg`. The value is as given in the lexical form of the XSD dateTime.
    #
    # @example
    #     (prefix ((: <http://example.org/>))
    #       (project (?s ?x)
    #         (extend ((?x (minutes ?date)))
    #           (bgp (triple ?s :date ?date)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-minutes
    class Minutes < Operator::Unary
      include Evaluatable

      NAME = :minutes

      ##
      # Returns the minutes part of arg as an integer.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand)
        raise TypeError, "expected an RDF::Literal::DateTime, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::DateTime)
        RDF::Literal(operand.object.minute)
      end
    end # Minutes
  end # Operator
end; end # SPARQL::Algebra
