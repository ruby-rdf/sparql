module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `sum` set function.
    #
    # @example
    #    (prefix ((: <http://www.example.org/>))
    #      (project (?sum)
    #        (extend ((?sum ?.0))
    #          (group () ((?.0 (sum ?o)))
    #            (bgp (triple ?s :dec ?o))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_aggSum
    class Sum < Operator::Unary
      include Aggregate

      NAME = :sum

      ##
      # Sum is a SPARQL set function that will return the numeric value obtained by summing the values within the aggregate group. Type promotion happens as per the op:numeric-add function, applied transitively, (see definition below) so the value of SUM(?x), in an aggregate group where ?x has values 1 (integer), 2.0e0 (float), and 3.0 (decimal) will be 6.0 (float).
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Term] The sum of the terms
      def apply(enum)
        enum.empty? ? RDF::Literal(0) : enum.collect(:+)
      end
    end # Sum
  end # Operator
end; end # SPARQL::Algebra
