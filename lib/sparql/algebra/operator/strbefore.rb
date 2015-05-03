module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL `strbefore` operator.
    #
    # @example
    #   (strbefore ?x ?y)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-strbefore
    # @see http://www.w3.org/TR/xpath-functions/#func-substring-before
    class StrBefore < Operator::Binary
      include Evaluatable

      NAME = :strbefore

      ##
      # The STRBEFORE function corresponds to the XPath fn:substring-before function. The arguments must be argument compatible otherwise an error is raised.
      #
      # For compatible arguments, if the lexical part of the second argument occurs as a substring of the lexical part of the first argument, the function returns a literal of the same kind as the first argument arg1 (simple literal, plain literal same language tag, xsd:string). The lexical form of the result is the substring of the lexical form of arg1 that precedes the first occurrence of the lexical form of arg2. If the lexical form of arg2 is the empty string, this is considered to be a match and the lexical form of the result is the empty string.
      #
      # If there is no such occurrence, an empty simple literal is returned.
      #
      # @example
      #     strbefore("abc","b") #=> "a"
      #     strbefore("abc"@en,"bc") #=> "a"@en
      #     strbefore("abc"@en,"b"@cy) #=> error
      #     strbefore("abc"^^xsd:string,"") #=> ""^^xsd:string
      #     strbefore("abc","xyz") #=> ""
      #     strbefore("abc"@en, "z"@en) #=> ""
      #     strbefore("abc"@en, "z") #=> ""
      #     strbefore("abc"@en, ""@en) #=> ""@en
      #     strbefore("abc"@en, "") #=> ""@en
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal]
      # @raise  [TypeError] if operands are not compatible
      def apply(left, right)
        case
        when !left.plain? || !right.plain?
          raise TypeError, "expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"
        when !left.compatible?(right)
          raise TypeError, "expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"
        when right.to_s.empty?
          # If the lexical form of arg2 is the empty string, this is considered to be a match and the lexical form of the result is is the empty string. 
          RDF::Literal("", language: left.language, datatype: left.datatype)
        when !left.to_s.include?(right.to_s)
          # If the lexical form of arg2 is the empty string, this is considered to be a match and the lexical form of the result is is the empty string. 
          RDF::Literal("")
        else
          parts = left.to_s.split(right.to_s)
          RDF::Literal(parts.first, language: left.language, datatype: left.datatype)
        end
      end
    end # StrBefore
  end # Operator
end; end # SPARQL::Algebra
