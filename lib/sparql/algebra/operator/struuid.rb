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
    #         (extend ((?length (strlen ?uuid)))
    #           (filter (&& (isLiteral ?uuid) (regex ?uuid "^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$" "i"))
    #             (extend ((?uuid (struuid)))
    #               (bgp))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-struuid
    class StrUUID < Operator::Nullary
      include Evaluatable

      NAME = :struuid

      ##
      # Return a string that is the scheme specific part of UUID. That is, as a simple literal, the result of generating a UUID, converting to a simple literal and removing the initial urn:uuid:.
      #
      # @return [RDF::URI]
      def apply
        RDF::Literal(SecureRandom.uuid)
      end
    end # StrUUID
  end # Operator
end; end # SPARQL::Algebra
