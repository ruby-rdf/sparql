module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL relational `<` (less than) comparison operator.
    #
    # @example
    #   (< ?x ?y)
    #
    # @see https://www.w3.org/TR/sparql11-query/#OperatorMapping
    # @see https://www.w3.org/TR/xpath-functions/#func-compare
    # @see https://www.w3.org/TR/xpath-functions/#func-numeric-less-than
    # @see https://www.w3.org/TR/xpath-functions/#func-boolean-less-than
    # @see https://www.w3.org/TR/xpath-functions/#func-dateTime-less-than
    class LessThan < Compare
      NAME = :<

      ##
      # Returns `true` if the first operand is less than the second
      # operand; returns `false` otherwise.
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if either operand is not a literal
      def apply(left, right, **options)
        #require 'byebug'; byebug if super == RDF::Literal(-1)
        RDF::Literal(super == RDF::Literal(-1))
      end
    end # LessThan
  end # Operator
end; end # SPARQL::Algebra
