module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isBlank` operator.
    #
    # [121] BuiltInCall ::= ... | 'isBlank' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX     :    <http://example.org/things#>
    #   SELECT ?x ?v WHERE {
    #     ?x :p ?v .
    #     FILTER isBlank(?v) .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (isBlank ?v)
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-isBlank
    class IsBlank < Operator::Unary
      include Evaluatable

      NAME = :isBlank

      ##
      # Returns `true` if the operand is an `RDF::Node`, `false` otherwise.
      #
      # @param  [RDF::Term] term
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand is not an RDF term
      def apply(term, **options)
        case term
          when RDF::Node then RDF::Literal::TRUE
          when RDF::Term then RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Term, but got #{term.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "isBlank(" + operands.first.to_sparql(**options) + ")"
      end
    end # IsBlank
  end # Operator
end; end # SPARQL::Algebra
