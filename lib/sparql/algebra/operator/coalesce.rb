module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `coalesce` function.
    #
    # [121] BuiltInCall ::= ... | 'COALESCE' ExpressionList 
    #
    # @example SPARQL Grammar
    #   PREFIX :        <http://example/>
    #   PREFIX xsd:     <http://www.w3.org/2001/XMLSchema#>
    #   
    #   SELECT ?X (SAMPLE(?v) AS ?S)
    #   {
    #     ?s :p ?v .
    #     OPTIONAL { ?s :q ?w }
    #   }
    #   GROUP BY (COALESCE(?w, "1605-11-05"^^xsd:date) AS ?X) 
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example/>) (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (project (?X ?S)
    #     (extend ((?S ??.0))
    #      (group
    #       ((?X (coalesce ?w "1605-11-05"^^xsd:date)))
    #       ((??.0 (sample ?v)))
    #       (leftjoin
    #        (bgp (triple ?s :p ?v))
    #        (bgp (triple ?s :q ?w)))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-coalesce
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
      def evaluate(bindings, **options)
        operands.each do |op|
          begin
            return op.evaluate(bindings, **options.merge(depth: options[:depth].to_i + 1))
          rescue
          end
        end
        raise TypeError, "None of the operands evaluated"
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "COALESCE(#{operands.to_sparql(delimiter: ', ', **options)})"
      end
    end # Coalesce
  end # Operator
end; end # SPARQL::Algebra
