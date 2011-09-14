module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isIRI`/`isURI` operator.
    #
    # @example
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (isIRI ?v)
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-isIRI
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
      def apply(term)
        case term
          when RDF::URI  then RDF::Literal::TRUE
          when RDF::Term then RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Term, but got #{term.inspect}"
        end
      end

      Operator::IsURI = IsIRI
    end # IsIRI
  end # Operator
end; end # SPARQL::Algebra
