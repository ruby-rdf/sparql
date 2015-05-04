module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL `strafter` operator.
    #
    # @example
    #   (strafter ?x ?y)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-strafter
    # @see http://www.w3.org/TR/xpath-functions/#func-substring-after
    class StrAfter < Operator::Binary
      include Evaluatable

      NAME = :strafter

      ##
      # The STRAFTER function corresponds to the XPath fn:substring-after function. The arguments must be argument compatible otherwise an error is raised.
      #
      # For compatible arguments, if the lexical part of the second argument occurs as a substring of the lexical part of the first argument, the function returns a literal of the same kind as the first argument arg1 (simple literal, plain literal same language tag, xsd:string). The lexical form of the result is the substring of the lexcial form of arg1 that follows the first occurrence of the lexical form of arg2. If the lexical form of arg2 is the empty string, this is considered to be a match and the lexical form of the result is the lexical form of arg1.
      #
      # If there is no such occurrence, an empty simple literal is returned.
      #
      # @example
      #     strafter("abc","b") #=> "c"
      #     strafter("abc"@en,"ab") #=> "c"@en
      #     strafter("abc"@en,"b"@cy) #=> error
      #     strafter("abc"^^xsd:string,"") #=> "abc"^^xsd:string
      #     strafter("abc","xyz") #=> ""
      #     strafter("abc"@en, "z"@en) #=> ""
      #     strafter("abc"@en, "z") #=> ""
      #     strafter("abc"@en, ""@en) #=> "abc"@en
      #     strafter("abc"@en, "") #=> "abc"@en
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal]
      # @raise  [TypeError] if operands are not compatible
      def apply(left, right)
        case
        when !left.compatible?(right)
          raise TypeError, "expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"
        when right.to_s.empty?
          # If the lexical form of arg2 is the empty string, this is considered to be a match and the lexical form of the result is the lexical form of arg1. 
          left
        when !left.to_s.include?(right.to_s)
          # If the lexical form of arg2 is the empty string, this is considered to be a match and the lexical form of the result is is the empty string. 
          RDF::Literal("")
        else
          parts = left.to_s.split(right.to_s)
          RDF::Literal(parts.last, datatype: left.datatype, language: left.language)
        end
      end
    end # StrAfter
  end # Operator
end; end # SPARQL::Algebra
