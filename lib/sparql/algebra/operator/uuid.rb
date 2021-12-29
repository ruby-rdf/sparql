require 'securerandom'

module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `uuid` function.
    #
    # [121] BuiltInCall ::= ... | 'UUID' NIL 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   ASK {
    #     BIND(UUID() AS ?u1)
    #     BIND(UUID() AS ?u2)
    #     FILTER(?u1 != ?u2)
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>) (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (ask
    #     (filter (!= ?u1 ?u2)
    #      (extend ((?u1 (uuid)) (?u2 (uuid)))
    #       (bgp)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-uuid
    class UUID < Operator::Nullary
      include Evaluatable

      NAME = :uuid

      ##
      # Return a fresh IRI from the UUID URN scheme. Each call of UUID() returns a different UUID. It must not be the "nil" UUID (all zeroes). The variant and version of the UUID is implementation dependent.
      #
      # @return [RDF::URI]
      def apply(**options)
        RDF::URI("urn:uuid:#{SecureRandom.uuid}")
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "UUID(" + operands.to_sparql(delimiter: ', ', **options) + ")"
      end
    end # UUID
  end # Operator
end; end # SPARQL::Algebra
