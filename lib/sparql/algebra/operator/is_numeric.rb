module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isNumeric` operator.
    #
    # Note numeric denotes typed literals with datatypes xsd:integer, xsd:decimal, xsd:float, and xsd:double, not derived types.
    #
    # @example
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (isNumeric ?v)
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-isNumeric
    class IsNumeric < Operator::Unary
      include Evaluatable

      NAME = :isnumeric

      ##
      # Returns `true` if the operand is an `RDF::Literal::Numeric`, `false`
      # otherwise.
      #
      # @param  [RDF::Term] term
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand is not an RDF term
      def apply(term)
        case term
          when RDF::Literal::NonPositiveInteger then RDF::Literal::FALSE
          when RDF::Literal::NonNegativeInteger then RDF::Literal::FALSE
          when RDF::Literal::Long then RDF::Literal::FALSE
          when RDF::Literal::Numeric then RDF::Literal::TRUE
          when RDF::Term    then RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Term, but got #{term.inspect}"
        end
      end
    end # IsNumeric
  end # Operator
end; end # SPARQL::Algebra
