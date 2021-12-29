module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `rand` operator.
    #
    # Returns a pseudo-random number between 0 (inclusive) and 1.0e0 (exclusive). Different numbers can be produced every time this function is invoked. Numbers should be produced with approximately equal probability.
    #
    # [121] BuiltInCall ::= ... | 'RAND' NIL 
    #
    # @example SPARQL Grammar
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   ASK {
    #     BIND(RAND() AS ?r)
    #     FILTER(DATATYPE(?r) = xsd:double && ?r >= 0.0 && ?r < 1.0)
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (ask
    #     (filter
    #      (&&
    #       (&& (= (datatype ?r) xsd:double) (>= ?r 0.0))
    #       (< ?r 1.0))
    #      (extend ((?r (rand)))
    #       (bgp)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#idp2130040
    class Rand < Operator::Nullary
      include Evaluatable

      NAME = :rand

      ##
      # Returns a pseudo-random number between 0 (inclusive) and 1.0e0 (exclusive). Different numbers can be produced every time this function is invoked. Numbers should be produced with approximately equal probability.
      #
      # @return [RDF::Literal::Double] random value
      def apply(**options)
        RDF::Literal::Double.new(Random.rand)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # Extracts projections
      #
      # @return [String]
      def to_sparql(**options)
        "RAND()"
      end
    end # Rand
  end # Operator
end; end # SPARQL::Algebra
