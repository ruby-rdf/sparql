module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `or` operator.
    #
    # @example
    #   (|| ?x ?y)
    #   (or ?x ?y)
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-logical-or
    # @see http://www.w3.org/TR/rdf-sparql-query/#evaluation
    class Or < Operator::Binary
      include Evaluatable

      NAME = [:or, :'||']

      ##
      # Initializes a new operator instance.
      #
      # @param  [RDF::Literal::Boolean] left
      #   the left operand
      # @param  [RDF::Literal::Boolean] right
      #   the right operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      # @raise  [TypeError] if any operand is invalid
      def initialize(left, right, options = {})
        super
      end

      ##
      # Returns the logical `OR` of the left operand and the right operand.
      #
      # Note that this operator operates on the effective boolean value
      # (EBV) of its operands.
      #
      # @param  [RDF::Query::Solution, #[]] bindings
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operands could not be coerced to a boolean literal
      def evaluate(bindings = {})
        begin
          left = boolean(operand(0).evaluate(bindings)).true?
        rescue TypeError
          left = nil
        end
        
        begin
          right = boolean(operand(1).evaluate(bindings)).true?
        rescue TypeError
          right = nil
        end

        # From http://www.w3.org/TR/rdf-sparql-query/#evaluation
        # A logical-or that encounters an error on only one branch will return TRUE if the other branch is TRUE
        # and an error if the other branch is FALSE.
        case
        when left.nil? && right.nil? then raise(TypeError)
        when left.nil?               then right ? RDF::Literal::TRUE : raise(TypeError)
        when right.nil?              then left ? RDF::Literal::TRUE : raise(TypeError)
        else                              RDF::Literal(left || right)
        end
      end
    end # Or
  end # Operator
end; end # SPARQL::Algebra
