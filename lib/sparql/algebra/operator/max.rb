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
      # @return [RDF::Term] The maximum value of the terms
      def apply(enum)
        raise TypeError, "Maximum of an empty multiset" if enum.empty?
        RDF::Literal(enum.max)
      end
    end # Max
  end # Operator
end; end # SPARQL::Algebra
