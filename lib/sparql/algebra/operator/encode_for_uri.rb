require 'uri'

module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `abs` operator.
    #
    # [121] BuiltInCall ::= ... | 'ENCODE_FOR_URI' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s ?str (ENCODE_FOR_URI(?str) AS ?encoded) WHERE {
    #     ?s :str ?str
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>))
    #    (project (?s ?str ?encoded)
    #     (extend ((?encoded (encode_for_uri ?str)))
    #      (bgp (triple ?s :str ?str)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-encode
    # @see https://www.w3.org/TR/xpath-functions/#func-abs
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
      def apply(operand, **options)
        case operand
          when RDF::Literal then RDF::Literal(CGI.escape(operand.to_s))
          else raise TypeError, "expected an RDF::Literal, but got #{operand.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "ENCODE_FOR_URI(#{operands.last.to_sparql(**options)})"
      end
    end # EncodeForURI
  end # Operator
end; end # SPARQL::Algebra
