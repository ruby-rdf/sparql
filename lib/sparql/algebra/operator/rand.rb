module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `rand` operator.
    #
    # Returns a pseudo-random number between 0 (inclusive) and 1.0e0 (exclusive). Different numbers can be produced every time this function is invoked. Numbers should be produced with approximately equal probability.
    #
    # @example
    #   (rand)
    #
    # @see http://www.w3.org/TR/sparql11-query/#idp2130040
    class Rand < Operator::Nullary
      include Evaluatable

      NAME = :rand

      ##
      # Returns a pseudo-random number between 0 (inclusive) and 1.0e0 (exclusive). Different numbers can be produced every time this function is invoked. Numbers should be produced with approximately equal probability.
      #
      # @return [RDF::Literal::Double] random value
      def apply
        RDF::Literal::Double.new(Random.rand)
      end
    end # Rand
  end # Operator
end; end # SPARQL::Algebra
