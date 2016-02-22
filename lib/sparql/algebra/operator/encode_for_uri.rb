require 'uri'

module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `abs` operator.
    #
    # @example
    #   (encode_for_uri ?x)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-encode
    # @see http://www.w3.org/TR/xpath-functions/#func-abs
    class EncodeForURI < Operator::Unary
      include Evaluatable

      NAME = :encode_for_uri

      ##
      # The `ENCODE_FOR_URI` function corresponds to the XPath fn:encode-for-uri function. It returns a simple literal with the lexical form obtained from the lexical form of its input after translating reserved characters according to the fn:encode-for-uri function.
      #
      # @example
      #     encode_for_uri("Los Angeles")	"Los%20Angeles"
      #     encode_for_uri("Los Angeles"@en)	"Los%20Angeles"
      #     encode_for_uri("Los Angeles"^^xsd:string)	"Los%20Angeles"
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a literal value
      def apply(operand)
        case operand
          when RDF::Literal then RDF::Literal(::URI.encode(operand.to_s))
          else raise TypeError, "expected an RDF::Literal, but got #{operand.inspect}"
        end
      end
    end # EncodeForURI
  end # Operator
end; end # SPARQL::Algebra
