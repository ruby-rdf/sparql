module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `sameTerm` operator.
    #
    # [121] BuiltInCall ::= ... | 'sameTerm' '(' Expression ',' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX     :    <http://example.org/things#>
    #   SELECT * {
    #     ?x1 :p ?v1 .
    #     ?x2 :p ?v2 .
    #     FILTER sameTerm(?v1, ?v2)
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/things#>))
    #    (filter (sameTerm ?v1 ?v2)
    #     (bgp (triple ?x1 :p ?v1) (triple ?x2 :p ?v2))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-sameTerm
    class SameTerm < Operator::Binary
      include Evaluatable

      NAME = :sameTerm

      ##
      # Returns `true` if the operands are the same RDF term; returns
      # `false` otherwise.
      #
      # @param  [RDF::Term] term1
      #   an RDF term
      # @param  [RDF::Term] term2
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if either operand is unbound
      def apply(term1, term2, **options)
        RDF::Literal(term1.eql?(term2))
      end

      ##
      # Returns an optimized version of this expression.
      #
      # Return true if variable operand1 is a bound variable and equals operand2
      #
      # @return [SameTerm] a copy of `self`
      # @see SPARQL::Algebra::Expression#optimize
      def optimize(**options)
        if operand(0).is_a?(Variable) && operand(0).bound? && operand(0).eql?(operand(1))
          RDF::Literal::TRUE
        else
          super # @see Operator#optimize!
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "sameTerm(#{operands.to_sparql(delimiter: ', ', **options)})"
      end
    end # SameTerm
  end # Operator
end; end # SPARQL::Algebra
