module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `OBJECT` operator.
    #
    # If triple is an RDF-star triple, the function returns the object of this triple. Passing anything other than an RDF-star triple is an error.
    #
    # @see https://w3c.github.io/rdf-star/rdf-star-cg-spec.html#object
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
