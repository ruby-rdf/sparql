module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL `contains` operator.
    #
    # [121] BuiltInCall ::= ... | 'CONTAINS' '(' Expression ',' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT ?s ?str WHERE {
    #     ?s :str ?str
    #     FILTER CONTAINS(?str, "a")
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?s ?str)
    #     (filter (contains ?str "a")
    #      (bgp (triple ?s :str ?str)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-contains
    # @see https://www.w3.org/TR/xpath-functions/#func-contains
    class Contains < Operator::Binary
      include Evaluatable

      NAME = :contains

      ##
      # The `CONTAINS` function corresponds to the XPath fn:contains. The arguments must be argument compatible otherwise an error is raised.
      #
      # @example
      #    contains("foobar", "bar") #=> true
      #    contains("foobar"@en, "foo"@en) #=> true
      #    contains("foobar"^^xsd:string, "bar"^^xsd:string) #=> true
      #    contains("foobar"^^xsd:string, "foo") #=> true
      #    contains("foobar", "bar"^^xsd:string) #=> true
      #    contains("foobar"@en, "foo") #=> true
      #    contains("foobar"@en, "bar"^^xsd:string) #=> true
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
        when left.to_s.include?(right.to_s) then RDF::Literal::TRUE
        else RDF::Literal::FALSE
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "contains(" + operands.to_sparql(delimiter: ', ', **options) + ")"
      end
    end # Contains
  end # Operator
end; end # SPARQL::Algebra
