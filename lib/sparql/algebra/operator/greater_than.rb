module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL relational `>` (greater than) comparison operator.
    #
    # @example
    #   (> ?x ?y)
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-greater-than
    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-greater-than
    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-greater-than
    class GreaterThan < Compare
      NAME = :>

      ##
      # Returns `true` if the first operand is greater than the second
      # operand; returns `false` otherwise.
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
    end # GreaterThan
  end # Operator
end; end # SPARQL::Algebra
