require 'securerandom'

module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `uuid` function.
    #
    # @example
    #     (prefix ((: <http://example.org/>)
    #              (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #       (project (?length)
    #         (extend ((?length (strlen (str ?uuid))))
    #           (filter (&& (isIRI ?uuid) (regex (str ?uuid) "^urn:uuid:[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$" "i"))
    #             (extend ((?uuid (uuid)))
    #               (bgp))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-uuid
    class UUID < Operator::Nullary
      include Evaluatable

      NAME = :uuid

      ##
      # Return a fresh IRI from the UUID URN scheme. Each call of UUID() returns a different UUID. It must not be the "nil" UUID (all zeroes). The variant and version of the UUID is implementation dependent.
      #
      # @return [RDF::URI]
      def apply
        RDF::URI("urn:uuid:#{SecureRandom.uuid}")
      end
    end # UUID
  end # Operator
end; end # SPARQL::Algebra
