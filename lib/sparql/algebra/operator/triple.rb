module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `triple` operator.
    #
    # @see xxx
    class Triple < Operator::Ternary
      include Evaluatable

      NAME = :triple

      ##
      # @param  [RDF::Term] subject
      # @param  [RDF::Term] predicate
      # @param  [RDF::Term] object
      # @return [RDF::URI]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(subject, predicate, object)
        triple = RDF::Statement(subject, predicate, object)
        raise TypeError, "valid components, but got #{triple.inspect}" unless triple.valid?
        triple
      end
    end # Triple
  end # Operator
end; end # SPARQL::Algebra
