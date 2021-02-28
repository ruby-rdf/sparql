module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `predicate` operator.
    #
    # Returns the predicate part of `arg` as a term.
    #
    # @see xxx
    class Predicate < Operator::Unary
      include Evaluatable

      NAME = :predicate

      ##
      # Returns the predicate part of arg.
      #
      # @param  [RDF::Statement] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a statement
      def apply(operand)
        raise TypeError, "expected an RDF::Statement, but got #{operand.inspect}" unless operand.is_a?(RDF::Statement)
        operand.predicate
      end
    end # Predicate
  end # Operator
end; end # SPARQL::Algebra
