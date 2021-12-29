module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `strdt` operator.
    #
    # [121] BuiltInCall ::= ... | 'STRDT' '(' Expression ',' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   SELECT ?s (STRDT(?str,xsd:string) AS ?str1) WHERE {
    #     ?s :str ?str
    #     FILTER(LANGMATCHES(LANG(?str), "en"))
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>) (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #     (project (?s ?str1)
    #       (extend ((?str1 (strdt ?str xsd:string)))
    #         (filter (langMatches (lang ?str) "en")
    #           (bgp (triple ?s :str ?str))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-strdt
    class StrDT < Operator::Binary
      include Evaluatable

      NAME = :strdt

      ##
      # Constructs a literal with lexical form and type as specified by the arguments.
      #
      # @param  [RDF::Literal] value
      #   a literal
      # @param  [RDF::URI] datatypeIRI
      #   datatype
      # @return [RDF::Literal] a datatyped literal
      # @see https://www.w3.org/TR/sparql11-query/#func-strdt
      def apply(value, datatypeIRI, **options)
        raise TypeError, "Literal #{value.inspect} is not simple" unless value.simple?
        RDF::Literal.new(value.to_s, datatype: datatypeIRI)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "STRDT(" + operands.to_sparql(delimiter: ', ', **options) + ")"
      end
    end # StrDT
  end # Operator
end; end # SPARQL::Algebra
