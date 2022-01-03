module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isNumeric` operator.
    #
    # Note numeric denotes typed literals with datatypes `xsd:integer`, `xsd:decimal`, `xsd:float`, and `xsd:double`, not derived types.
    #
    # [121] BuiltInCall ::= ... | 'isNumeric' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX     :    <http://example.org/things#>
    #   SELECT ?x ?v WHERE {
    #     ?x :p ?v .
    #     FILTER isNumeric(?v) .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (isNumeric ?v)
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-isNumeric
    class IsNumeric < Operator::Unary
      include Evaluatable

      NAME = :isNumeric

      ##
      # Returns `true` if the operand is an `RDF::Literal::Numeric`, `false`
      # otherwise.
      #
      # @param  [RDF::Term] term
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand is not an RDF term
      def apply(term, **options)
        case term
          when RDF::Literal::NonPositiveInteger then RDF::Literal::FALSE
          when RDF::Literal::NonNegativeInteger then RDF::Literal::FALSE
          when RDF::Literal::Long then RDF::Literal::FALSE
          when RDF::Literal::Numeric then RDF::Literal::TRUE
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
        "isNumeric(" + operands.first.to_sparql(**options) + ")"
      end
    end # IsNumeric
  end # Operator
end; end # SPARQL::Algebra
