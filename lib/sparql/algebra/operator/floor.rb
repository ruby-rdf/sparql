module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `floor` operator.
    #
    # @example
    #   (floor ?x)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-floor
    # @see http://www.w3.org/TR/xpath-functions/#func-floor
    class Floor < Operator::Unary
      include Evaluatable

      NAME = [:floor]

      ##
      # Returns the largest (closest to positive infinity) number with no fractional part that is not greater than the value of `arg`. An error is raised if `arg` is not a numeric value.
      #
      # If type of $arg is one of the four numeric types xs:float, xs:double, xs:decimal or xs:integer the type of the result is the same as the type of $arg. If the type of $arg is a type derived from one of the numeric types, the result is an instance of the base numeric type.
      #
      # For float and double arguments, if the argument is positive zero, then positive zero is returned. If the argument is negative zero, then negative zero is returned.
      #
      # @param  [RDF::Literal] operand
      #   the operand
      # @return [RDF::Literal] literal of same type
      # @raise  [TypeError] if the operand is not a numeric value
      def apply(operand)
        case operand
          when RDF::Literal::Numeric then operand.floor
          else raise TypeError, "expected an RDF::Literal::Numeric, but got #{operand.inspect}"
        end
      end
    end # Floor
  end # Operator
end; end # SPARQL::Algebra
