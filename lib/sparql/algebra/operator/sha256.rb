require 'digest'

module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `sha256` operator.
    #
    # Returns the SHA256 checksum, as a hex digit string, calculated on the UTF-8 representation of the simple literal or lexical form of the `xsd:string`. Hex digits `SHOULD` be in lower case.
    #
    # @example
    #     (prefix ((: <http://example.org/>))
    #       (project (?hash)
    #         (extend ((?hash (sha256 ?l)))
    #           (bgp (triple :s1 :str ?l)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-sha256
    class SHA256 < Operator::Unary
      include Evaluatable

      NAME = :sha256

      ##
      # Returns the SHA256 checksum, as a hex digit string, calculated on the UTF-8 representation of the simple literal or lexical form of the xsd:string. Hex digits should be in lower case.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(operand)
        raise TypeError, "expected an RDF::Literal, but got #{operand.inspect}" unless operand.literal?
        raise TypeError, "expected simple literal or xsd:string, but got #{operand.inspect}" unless (operand.datatype || RDF::XSD.string) == RDF::XSD.string
        RDF::Literal(Digest::SHA256.new.hexdigest(operand.to_s))
      end
    end # SHA256
  end # Operator
end; end # SPARQL::Algebra
