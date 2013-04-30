module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `strlen` operator.
    #
    # @example
    #   (strlen ?x)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-strlen
    # @see http://www.w3.org/TR/xpath-functions/#func-string-length
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
      def apply(operand)
        raise TypeError, "expected a plain RDF::Literal, but got #{operand.inspect}" unless operand.literal? && operand.plain?
        RDF::Literal(operand.to_s.length)
      end
    end # StrLen
  end # Operator
end; end # SPARQL::Algebra
