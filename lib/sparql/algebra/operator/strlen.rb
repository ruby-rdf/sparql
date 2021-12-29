module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `strlen` operator.
    #
    # [121] BuiltInCall ::= ... 'STRLEN' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?str (STRLEN(?str) AS ?len) WHERE {
    #     ?s :str ?str
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?str ?len)
    #     (extend ((?len (strlen ?str)))
    #      (bgp (triple ?s :str ?str)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-strlen
    # @see https://www.w3.org/TR/xpath-functions/#func-string-length
    class StrLen < Operator::Unary
      include Evaluatable

      NAME = :strlen

      ##
      # The strlen function corresponds to the XPath fn:string-length function and returns an xsd:integer equal to the length in characters of the lexical form of the literal.
      #
      # @example
      #     strlen("chat")	4
      #     strlen("chat"@en)	4
      #     strlen("chat"^^xsd:string)	4
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal::Integer] length of string
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand, **options)
        raise TypeError, "expected a plain RDF::Literal, but got #{operand.inspect}" unless operand.literal? && operand.plain?
        RDF::Literal(operand.to_s.length)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "STRLEN(" + operands.to_sparql(delimiter: ', ', **options) + ")"
      end
    end # StrLen
  end # Operator
end; end # SPARQL::Algebra
