module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL relational `<=` (less than or equal) comparison operator.
    #
    # @example
    #   (<= ?x ?y)
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-less-than
    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-less-than
    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-less-than
    class LessThanOrEqual < Compare
      NAME = :<=

      ##
      # Returns `true` if the first operand is less than or equal to the
      # second operand; returns `false` otherwise.
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if either operand is not a literal
      def apply(left, right)
        super
      end
    end # LessThanOrEqual
  end # Operator
end; end # SPARQL::Algebra
