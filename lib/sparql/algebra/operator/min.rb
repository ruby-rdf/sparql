module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `min` set function.
    #
    # @example
    #    (prefix ((: <http://www.example.org/>))
    #      (project (?max)
    #        (extend ((?min ?.0))
    #          (group () ((?.0 (min ?o)))
    #            (bgp (triple ?s ?p ?o))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_aggMin
    class Min < Operator::Unary
      include Aggregate

      NAME = :min

      ##
      # Min is a SPARQL set function that return the minimum value from a group respectively.
      #
      # It makes use of the SPARQL ORDER BY ordering definition, to allow ordering over arbitrarily typed expressions.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Literal] The maximum value of the terms
      def apply(enum)
        if enum.empty?
          raise TypeError, "Minumuim of an empty multiset"
        elsif enum.flatten.all? {|n| n.literal?}
          RDF::Literal(enum.flatten.min)
        else
          raise TypeError, "Minumuim of non-literals: #{enum.flatten}"
        end
      end
    end # Min
  end # Operator
end; end # SPARQL::Algebra
