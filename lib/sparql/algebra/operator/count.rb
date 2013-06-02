module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `count` set function.
    #
    # @example
    #    (prefix ((: <http://www.example.org>))
    #      (project (?C)
    #        (extend ((?C ?.0))
    #          (group () ((?.0 (count ?O)))
    #            (bgp (triple ?S ?P ?O))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_aggCount
    class Count < Operator
      include Aggregate

      NAME = :count

      ##
      # Count is a SPARQL set function which counts the number of times a given expression has a bound, and non-error value within the aggregate group.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Literal::Integer] The number of non-error terms in the multiset
      def apply(enum)
        RDF::Literal(enum.length)
      end
    end # Count
  end # Operator
end; end # SPARQL::Algebra
