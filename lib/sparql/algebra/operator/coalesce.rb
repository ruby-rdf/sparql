module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `coalesce` function.
    #
    # @example
    #     (prefix ((: <http://example.org/>)
    #              (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #       (project (?cx ?div ?def ?err)
    #         (extend ((?cx (coalesce ?x -1))
    #                  (?div (coalesce (/ ?o ?x) -2))
    #                  (?def (coalesce ?z -3))
    #                  (?err (coalesce ?z)))
    #           (leftjoin
    #             (bgp (triple ?s :p ?o))
    #             (bgp (triple ?s :q ?x))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-coalesce
    class Coalesce < Operator
      include Evaluatable

      NAME = :coalesce

      ##
      # The COALESCE function form returns the RDF term value of the first expression that evaluates without error. In SPARQL, evaluating an unbound variable raises an error.
      #
      # If none of the arguments evaluates to an RDF term, an error is raised. If no expressions are evaluated without error, an error is raised.
      #
      # @example
      #   Suppose ?x = 2 and ?y is not bound in some query solution:
      #
      #     COALESCE(?x, 1/0) #=> 2, the value of x
      #     COALESCE(1/0, ?x) #=> 2
      #     COALESCE(5, ?x) #=> 5
      #     COALESCE(?y, 3) #=> 3
      #     COALESCE(?y) #=> raises an error because y is not bound.
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @return [RDF::Term]
      # @raise  [TypeError] if none of the operands succeeds
      def evaluate(bindings, options = {})
        operands.each do |op|
          begin
            return op.evaluate(bindings, options.merge(depth: options[:depth].to_i + 1))
          rescue
          end
        end
        raise TypeError, "None of the operands evaluated"
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
    end # Coalesce
  end # Operator
end; end # SPARQL::Algebra
