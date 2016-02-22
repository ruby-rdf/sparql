module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `abs` operator.
    #
    # @example
    #   (abs ?x)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-abs
    # @see http://www.w3.org/TR/xpath-functions/#func-abs
    class Abs < Operator::Unary
      include Evaluatable

      NAME = [:abs]

      ##
      # Returns the absolute value of `arg`. An error is raised if `arg` is not a numeric value.
      # 
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand)
        case operand
          when RDF::Literal::Numeric then operand.abs
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{operand.inspect}"
        end
      end
    end # Abs
  end # Operator
end; end # SPARQL::Algebra
