module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `lang` operator.
    #
    # [121] BuiltInCall ::= ... | 'LANG' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example/> 
    #   
    #   SELECT ?x
    #   { ?x :p ?v . 
    #     FILTER ( lang(?v) != '@NotALangTag@' )
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (project (?x)
    #     (filter (!= (lang ?v) "@NotALangTag@")
    #      (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-lang
    class Lang < Operator::Unary
      include Evaluatable

      NAME = :lang

      ##
      # Returns the language tag of the operand, if it has one.
      #
      # If the operand has no language tag, returns `""`.
      #
      # @param  [RDF::Literal] literal
      #   a literal
      # @return [RDF::Literal] a simple literal
      # @raise  [TypeError] if the operand is not a literal
      def apply(literal, **options)
        case literal
          when RDF::Literal then RDF::Literal(literal.language.to_s)
          else raise TypeError, "expected an RDF::Literal, but got #{literal.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "lang(" + operands.first.to_sparql(**options) + ")"
      end
    end # Lang
  end # Operator
end; end # SPARQL::Algebra
