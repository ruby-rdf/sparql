module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL relational `!=` (not equal) comparison operator.
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal
    class NotEqual < Equal
      NAME = :'!='

      ##
      # Returns `true` if the operands are not equal; returns `false`
      # otherwise.
      #
      # @param  [RDF::Term] term1
      #   an RDF term
      # @param  [RDF::Term] term2
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if either operand is not an RDF term
      def apply(term1, term2)
        RDF::Literal(super.false?)
      end
    end # NotEqual
  end # Operator
end; end # SPARQL::Algebra
