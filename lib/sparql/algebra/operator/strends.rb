module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL `strends` operator.
    #
    # [121] BuiltInCall ::= ... | 'STRENDS' '(' Expression ',' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s ?str WHERE {
    #     ?s :str ?str
    #     FILTER STRENDS(?str, "a")
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?str)
    #     (filter (strends ?str "a")
    #      (bgp (triple ?s :str ?str)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-strends
    # @see https://wwww.w3.org/TR/xpath-functions/#func-ends-with
    class StrEnds < Operator::Binary
      include Evaluatable

      NAME = :strends

      ##
      # The STRENDS function corresponds to the XPath fn:ends-with function. The arguments must be argument compatible otherwise an error is raised.
      # 
      # For such input pairs, the function returns true if the lexical form of arg1 ends with the lexical form of arg2, otherwise it returns false.
      #
      # @example
      #     strEnds("foobar", "bar") #=> true
      #     strEnds("foobar"@en, "bar"@en) #=> true
      #     strEnds("foobar"^^xsd:string, "bar"^^xsd:string) #=> true
      #     strEnds("foobar"^^xsd:string, "bar") #=> true
      #     strEnds("foobar", "bar"^^xsd:string) #=> true
      #     strEnds("foobar"@en, "bar") #=> true
      #     strEnds("foobar"@en, "bar"^^xsd:string) #=> true
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal::Boolean]
      # @raise  [TypeError] if operands are not compatible
      def apply(left, right, **options)
        case
        when !left.compatible?(right)
          raise TypeError, "expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"
        when left.to_s.end_with?(right.to_s) then RDF::Literal::TRUE
        else RDF::Literal::FALSE
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "STRENDS(" + operands.to_sparql(delimiter: ', ', **options) + ")"
      end
    end # StrEnds
  end # Operator
end; end # SPARQL::Algebra
