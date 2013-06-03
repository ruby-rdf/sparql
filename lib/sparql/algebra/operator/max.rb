module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `max` set function.
    #
    # @example
    #    (prefix ((: <http://www.example.org/>))
    #      (project (?max)
    #        (extend ((?max ?.0))
    #          (group () ((?.0 (max ?o)))
    #            (bgp (triple ?s ?p ?o))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_aggMax
    class Max < Operator::Unary
      include Aggregate

      NAME = :max

      ##
      # Max is a SPARQL set function that return the maximum value from a group respectively.
      #
      # It makes use of the SPARQL ORDER BY ordering definition, to allow ordering over arbitrarily typed expressions.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Literal] The maximum value of the terms
      def apply(enum)
        if enum.empty?
          raise TypeError, "Maximum of an empty multiset"
        elsif enum.flatten.all? {|n| n.literal?}
          RDF::Literal(enum.flatten.max)
        else
          raise TypeError, "Maximum of non-literals: #{enum.flatten}"
        end
      end
    end # Max
  end # Operator
end; end # SPARQL::Algebra
