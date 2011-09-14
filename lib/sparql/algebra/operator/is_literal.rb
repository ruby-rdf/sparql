module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isLiteral` operator.
    #
    # @example
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (isLiteral ?v)
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-isLiteral
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
      def apply(term)
        case term
          when RDF::Literal then RDF::Literal::TRUE
          when RDF::Term    then RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Term, but got #{term.inspect}"
        end
      end
    end # IsLiteral
  end # Operator
end; end # SPARQL::Algebra
