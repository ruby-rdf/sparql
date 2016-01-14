module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `and` operator.
    #
    # @example
    #   (&& ?x ?y)
    #   (and ?x ?y)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-logical-and
    # @see http://www.w3.org/TR/sparql11-query/#evaluation
    class And < Operator::Binary
      include Evaluatable

      NAME = [:'&&', :and]

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
      # Returns a logical `AND` of `left` and `right`. Note that logical-and operates on the effective boolean value of its arguments.
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operands could not be coerced to boolean literals
      def evaluate(bindings, options = {})
        begin
          left = boolean(operand(0).evaluate(bindings, options.merge(depth: options[:depth].to_i + 1))).true?
        rescue TypeError
          left = nil
        end
        
        begin
          right = boolean(operand(1).evaluate(bindings, options.merge(depth: options[:depth].to_i + 1))).true?
        rescue TypeError
          right = nil
        end

        # From http://www.w3.org/TR/sparql11-query/#evaluation
        # A logical-and that encounters an error on only one branch will return an error if the other branch is
        # TRUE and FALSE if the other branch is FALSE.
        case
        when left.nil? && right.nil? then raise(TypeError)
        when left.nil?               then right ? raise(TypeError) : RDF::Literal::FALSE
        when right.nil?              then left  ? raise(TypeError) : RDF::Literal::FALSE
        else                              RDF::Literal(left && right)
        end
      end
    end # And
  end # Operator
end; end # SPARQL::Algebra
