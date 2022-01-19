module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isLiteral` operator.
    #
    # [121] BuiltInCall ::= ... | 'isLiteral' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX     :    <http://example.org/things#>
    #   SELECT ?x ?v WHERE {
    #     ?x :p ?v .
    #     FILTER isLiteral(?v) .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (isLiteral ?v)
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-isLiteral
    class IsLiteral < Operator::Unary
      include Evaluatable

      NAME = :isLiteral

      ##
      # Returns `true` if the operand is an `RDF::Literal`, `false`
      # otherwise.
      #
      # @param  [RDF::Term] term
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand is not an RDF term
      def apply(term, **options)
        case term
          when RDF::Literal then RDF::Literal::TRUE
          when RDF::Term    then RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Term, but got #{term.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "isLiteral(" + operands.first.to_sparql(**options) + ")"
      end
    end # IsLiteral
  end # Operator
end; end # SPARQL::Algebra
