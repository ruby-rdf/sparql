module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `object` operator.
    #
    # Returns the object part of `arg` as a term.
    #
    # @see xxx
    class Object < Operator::Unary
      include Evaluatable

      NAME = :object

      ##
      # Returns the object part of arg.
      #
      # @param  [RDF::Statement] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a statement
      def apply(operand)
        raise TypeError, "expected an RDF::Statement, but got #{operand.inspect}" unless operand.is_a?(RDF::Statement)
        operand.object
      end
    end # Object
  end # Operator
end; end # SPARQL::Algebra
