module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL relational `<=` (less than or equal) comparison operator.
    #
    # [114] RelationalExpression    ::= NumericExpression ('<=' NumericExpression)?
    #
    # @example SPARQL Grammar
    #   PREFIX  xsd: <http://www.w3.org/2001/XMLSchema#>
    #   PREFIX  : <http://example.org/things#>
    #   SELECT  ?x
    #   WHERE { ?x :p ?v . FILTER ( ?v <= 1 ) }
    #
    # @example SSE
    #   (prefix
    #    ((xsd: <http://www.w3.org/2001/XMLSchema#>) (: <http://example.org/things#>))
    #    (project (?x) (filter (<= ?v 1) (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#OperatorMapping
    # @see https://www.w3.org/TR/xpath-functions/#func-compare
    # @see https://www.w3.org/TR/xpath-functions/#func-numeric-less-than
    # @see https://www.w3.org/TR/xpath-functions/#func-boolean-less-than
    # @see https://www.w3.org/TR/xpath-functions/#func-dateTime-less-than
    class LessThanOrEqual < Compare
      NAME = :<=

      ##
      # Returns `true` if the first operand is less than or equal to the
      # second operand; returns `false` otherwise.
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if either operand is not a literal
      def apply(left, right, **options)
        RDF::Literal(super <= RDF::Literal(0))
      end
    end # LessThanOrEqual
  end # Operator
end; end # SPARQL::Algebra
