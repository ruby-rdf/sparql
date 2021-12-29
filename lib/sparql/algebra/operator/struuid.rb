require 'securerandom'

module SPARQL; module Algebra
  class Operator
    ##
    # [121] BuiltInCall ::= ... | 'STRUUID' NIL 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   SELECT (STRLEN(?uuid) AS ?length)
    #   WHERE {
    #     BIND(STRUUID() AS ?uuid)
    #     FILTER(ISLITERAL(?uuid) && REGEX(?uuid, "^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$", "i"))
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>) (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (project (?length)
    #     (extend ((?length (strlen ?uuid)))
    #      (filter
    #       (&&
    #        (isLiteral ?uuid)
    #        (regex ?uuid "^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$" "i"))
    #       (extend ((?uuid (struuid)))
    #        (bgp))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-struuid
    class StrUUID < Operator::Nullary
      include Evaluatable

      NAME = :struuid

      ##
      # Return a string that is the scheme specific part of UUID. That is, as a simple literal, the result of generating a UUID, converting to a simple literal and removing the initial urn:uuid:.
      #
      # @return [RDF::URI]
      def apply(**options)
        RDF::Literal(SecureRandom.uuid)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "STRUUID(" + operands.to_sparql(delimiter: ', ', **options) + ")"
      end
    end # StrUUID
  end # Operator
end; end # SPARQL::Algebra
