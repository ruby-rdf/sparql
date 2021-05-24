module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `triple` operator.
    #
    # If the 3-tuple (term1, term2, term3) is an RDF-star triple, the function returns this triple. If the 3-tuple is not an RDF-star triple, then the function raises an error.
    #
    # @see https://w3c.github.io/rdf-star/rdf-star-cg-spec.html#triple
    class Triple < Operator::Ternary
      include Evaluatable

      NAME = :triple

      ##
      # @param  [RDF::Term] subject
      # @param  [RDF::Term] predicate
      # @param  [RDF::Term] object
      # @return [RDF::URI]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(subject, predicate, object, **options)
        triple = RDF::Statement(subject, predicate, object)
        raise TypeError, "valid components, but got #{triple.inspect}" unless triple.valid?
        triple
      end
    end # Triple
  end # Operator
end; end # SPARQL::Algebra
