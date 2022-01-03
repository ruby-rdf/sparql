module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isIRI`/`isURI` operator.
    #
    # [121] BuiltInCall ::= ... | 'isIRI' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX     :    <http://example.org/things#>
    #   SELECT ?x ?v WHERE {
    #     ?x :p ?v .
    #     FILTER isIRI(?v) .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (isIRI ?v)
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-isIRI
    class IsIRI < Operator::Unary
      include Evaluatable

      NAME = [:isIRI, :isURI]

      ##
      # Returns `true` if the operand is an `RDF::URI`, `false` otherwise.
      #
      # @param  [RDF::Term] term
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand is not an RDF term
      def apply(term, **options)
        case term
          when RDF::URI  then RDF::Literal::TRUE
          when RDF::Term then RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Term, but got #{term.inspect}"
        end
      end

      Operator::IsURI = IsIRI

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "isIRI(" + operands.first.to_sparql(**options) + ")"
      end
    end # IsIRI
  end # Operator
end; end # SPARQL::Algebra
