module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL relational `!=` (not equal) comparison operator.
    #
    # [114] RelationalExpression    ::= NumericExpression ('!=' NumericExpression)?
    #
    # @example SPARQL Grammar
    #   PREFIX  xsd: <http://www.w3.org/2001/XMLSchema#>
    #   PREFIX  : <http://example.org/things#>
    #   SELECT  ?x
    #   WHERE { ?x :p ?v . FILTER ( ?v != 1 ) }
    #
    # @example SSE
    #   (prefix
    #    ((xsd: <http://www.w3.org/2001/XMLSchema#>) (: <http://example.org/things#>))
    #    (project (?x) (filter (!= ?v 1) (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#OperatorMapping
    # @see https://www.w3.org/TR/sparql11-query/#func-RDFterm-equal
    class NotEqual < Equal
      NAME = :'!='

      ##
      # Returns `true` if the operands are not equal; returns `false`
      # otherwise.
      #
      # Comparing unknown datatypes might have different lexical forms but be the same value.
      #
      # @param  [RDF::Term] term1
      #   an RDF term
      # @param  [RDF::Term] term2
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if either operand is not an RDF term
      def apply(term1, term2, **options)
        RDF::Literal(super.false?)
      end
    end # NotEqual
  end # Operator
end; end # SPARQL::Algebra
