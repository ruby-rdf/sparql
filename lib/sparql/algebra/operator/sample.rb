module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `sample` set function.
    #
    # @example
    #   (prefix ((: <http://www.example.org/>))
    #     (filter (|| (|| (= ?sample 1.0) (= ?sample 2.2)) (= ?sample 3.5))
    #       (project (?sample)
    #         (extend ((?sample ?.0))
    #           (group () ((?.0 (sample ?o)))
    #             (bgp (triple ?s :dec ?o)))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_aggSample
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
