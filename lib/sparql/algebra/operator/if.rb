module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `if` function.
    #
    # @example
    #     (base <http://example.org/>
    #       (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>))
    #         (project (?o ?integer)
    #           (extend ((?integer (if (= (lang ?o) "ja") true false)))
    #             (bgp (triple ?s ?p ?o))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-if
    class If < Operator::Ternary
      include Evaluatable
      
      NAME = :if

      ##
      # The IF function form evaluates the first argument, interprets it as a effective boolean value, then returns the value of `expression2` if the EBV is true, otherwise it returns the value of `expression3`. Only one of `expression2` and `expression3` is evaluated. If evaluating the first argument raises an error, then an error is raised for the evaluation of the IF expression.
      #
      # @example
      #
      #     IF(?x = 2, "yes", "no") #=> "yes"
      #     IF(bound(?y), "yes", "no") #=> "no"
      #     IF(?x=2, "yes", 1/?z) #=> "yes", the expression 1/?z is not evaluated
      #     IF(?x=1, "yes", 1/?z) #=> raises an error
      #     IF("2" > 1, "yes", "no") #=> raises an error
      #
      # Evaluates the first operand and returns the evaluation of either the second or third operands
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @return [RDF::Term]
      # @raise [TypeError]
      def evaluate(bindings, options = {})
        operand(0).evaluate(bindings, options.merge(depth: options[:depth].to_i + 1)) == RDF::Literal::TRUE ?
          operand(1).evaluate(bindings, options.merge(depth: options[:depth].to_i + 1).merge(depth: options[:depth].to_i + 1)) :
          operand(2).evaluate(bindings, options.merge(depth: options[:depth].to_i + 1))
        rescue
          raise TypeError
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Return optimized query
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        operands = operands.map(&:optimize)
      end
    end # If
  end # Operator
end; end # SPARQL::Algebra
