module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `subject` operator.
    #
    # Returns the subject part of `arg` as a term.
    #
    # @see xxx
    class Subject < Operator::Unary
      include Evaluatable

      NAME = :subject

      ##
      # Returns the subject part of arg.
      #
      # @param  [RDF::Statement] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a statement
      def apply(operand)
        raise TypeError, "expected an RDF::Statement, but got #{operand.inspect}" unless operand.is_a?(RDF::Statement)
        operand.subject
      end
    end # Subject
  end # Operator
end; end # SPARQL::Algebra
