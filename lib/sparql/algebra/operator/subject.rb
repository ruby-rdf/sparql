module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `SUBJECT` operator.
    #
    # Returns the subject part of `arg` as a term.
    #
    # If triple is an RDF-star triple, the function returns the subject of this triple. Passing anything other than an RDF-star triple is an error.
    #
    # @see https://w3c.github.io/rdf-star/rdf-star-cg-spec.html#subject
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
