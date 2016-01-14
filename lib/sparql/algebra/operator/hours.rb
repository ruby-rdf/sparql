module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `hours` operator.
    #
    # @example
    #     (prefix ((: <http://example.org/>))
    #       (project (?s ?x)
    #         (extend ((?x (hours ?date)))
    #           (bgp (triple ?s :date ?date)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-hours
    class Hours < Operator::Unary
      include Evaluatable

      NAME = :hours

      ##
      # Returns the hours part of `arg` as an integer. The value is as given in the lexical form of the XSD dateTime.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand)
        raise TypeError, "expected an RDF::Literal::DateTime, but got #{operand.inspect}" unless operand.is_a?(RDF::Literal::DateTime)
        RDF::Literal(operand.object.hour)
      end
    end # Hours
  end # Operator
end; end # SPARQL::Algebra
