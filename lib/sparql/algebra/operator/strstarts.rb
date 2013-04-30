module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL `strstarts` operator.
    #
    # @example
    #   (strstarts ?x ?y)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-strstarts
    # @see http://www.w3.org/TR/xpath-functions/#func-starts-with
    class StrStarts < Operator::Binary
      include Evaluatable

      NAME = :strstarts

      ##
      # The STRSTARTS function corresponds to the XPath fn:starts-with function. The arguments must be argument compatible otherwise an error is raised.
      #
      # For such input pairs, the function returns true if the lexical form of arg1 starts with the lexical form of arg2, otherwise it returns false.
      #
      # @example
      #     strStarts("foobar", "foo") #=> true
      #     strStarts("foobar"@en, "foo"@en) #=> true
      #     strStarts("foobar"^^xsd:string, "foo"^^xsd:string) #=> true
      #     strStarts("foobar"^^xsd:string, "foo") #=> true
      #     strStarts("foobar", "foo"^^xsd:string) #=> true
      #     strStarts("foobar"@en, "foo") #=> true
      #     strStarts("foobar"@en, "foo"^^xsd:string) #=> true
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal::Boolean]
      # @raise  [TypeError] if operands are not compatible
      def apply(left, right)
        case
        when !left.compatible?(right)
          raise TypeError, "expected two RDF::Literal operands, but got #{left.inspect} and #{right.inspect}"
        when left.to_s.start_with?(right.to_s) then RDF::Literal::TRUE
        else RDF::Literal::FALSE
        end
      end
    end # StrStarts
  end # Operator
end; end # SPARQL::Algebra
