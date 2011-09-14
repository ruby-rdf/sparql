module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL relational `=` (equal) comparison operator.
    #
    # @example
    #   (= ?x ?y)
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal
    class Equal < Compare
      NAME = :'='

      ##
      # Returns `true` if the operands are equal; returns `false` otherwise.
      #
      # @param  [RDF::Term] term1
      #   an RDF term
      # @param  [RDF::Term] term2
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if either operand is not an RDF term or operands are not comperable
      #
      # @see {RDF::Term#==}
      def apply(term1, term2)
        term1 = term1.dup.extend(RDF::TypeCheck)
        term2 = term2.dup.extend(RDF::TypeCheck)
        RDF::Literal(term1 == term2)
      end
    end # Equal
  end # Operator
end; end # SPARQL::Algebra
