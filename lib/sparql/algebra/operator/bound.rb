module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `bound` operator.
    #
    # @example
    #   (prefix ((: <http://example.org/ns#>))
    #     (project (?a ?c)
    #       (filter (! (bound ?e))
    #         (leftjoin
    #           (bgp (triple ?a :b ?c))
    #           (bgp (triple ?c :d ?e))))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-bound
    class Bound < Operator::Unary
      include Evaluatable

      NAME = :bound

      ##
      # Initializes a new operator instance.
      #
      # @param  [RDF::Query::Variable] var
      #   a variable
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      # @raise  [TypeError] if any operand is invalid
      def initialize(var, options = {})
        super
      end

      ##
      # Returns `true` if the operand is a variable that is bound to a
      # value in the given `bindings`, `false` otherwise.
      #
      # @param  [RDF::Query::Solution, #[]] bindings
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand is not a variable
      def evaluate(bindings = {})
        case var = operand
          when Variable
            operand.evaluate(bindings) ? RDF::Literal::TRUE : RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Query::Variable, but got #{var.inspect}"
        end
      end
    end # Bound
  end # Operator
end; end # SPARQL::Algebra
