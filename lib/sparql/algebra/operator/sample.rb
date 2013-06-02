module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `lcase` operator.
    #
    # @example
    #   (lcase ?x)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-lcase
    # @see http://www.w3.org/TR/xpath-functions/#func-lcase
    class Sample < Operator::Unary
      include Aggregate

      NAME = :sample

      ##
      # Sample is a set function which returns an arbitrary value from the multiset passed to it.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Term] An arbitrary term
      # @raise  [TypeError] If enum is empty
      def apply(enum)
        enum.detect(lambda {raise TypeError, "Sampling an empty multiset"}) {|e| e.first}.first
      end
    end # LCase
  end # Operator
end; end # SPARQL::Algebra
