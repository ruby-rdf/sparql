module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isTRIPLE` operator.
    #
    # Returns true if term is an RDF-star triple. Returns false otherwise.
    #
    # @see https://w3c.github.io/rdf-star/rdf-star-cg-spec.html#istriple
    class IsTriple < Operator::Unary
      include Evaluatable

      NAME = :isTRIPLE

      ##
      # Returns `true` if the operand is an `RDF::Statement`, `false` otherwise.
      #
      # @param  [RDF::Term] term
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand is not an RDF term
      def apply(term, **options)
        case term
          when RDF::Statement  then RDF::Literal::TRUE
          when RDF::Term then RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Term, but got #{term.inspect}"
        end
      end
    end # IsTriple
  end # Operator
end; end # SPARQL::Algebra
