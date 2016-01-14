module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL relational `=` (equal) comparison operator.
    #
    # @example
    #   (= ?x ?y)
    #
    # @see http://www.w3.org/TR/sparql11-query/#OperatorMapping
    # @see http://www.w3.org/TR/sparql11-query/#func-RDFterm-equal
    class Equal < Compare
      NAME = :'='

      ##
      # Returns TRUE if `term1` and `term2` are the same RDF term as defined in Resource Description Framework (RDF): Concepts and Abstract Syntax [CONCEPTS]; produces a type error if the arguments are both literal but are not the same RDF term *; returns FALSE otherwise. `term1` and `term2` are the same if any of the following is true:
      #
      # * term1 and term2 are equivalent IRIs as defined in 6.4 RDF URI References of [CONCEPTS].
      # * term1 and term2 are equivalent literals as defined in 6.5.1 Literal Equality of [CONCEPTS].
      # * term1 and term2 are the same blank node as described in 6.6 Blank Nodes of [CONCEPTS].
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
