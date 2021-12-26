module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `exists` operator.
    #
    # There is a filter operator EXISTS that takes a graph pattern. EXISTS returns `true`/`false` depending on whether the pattern matches the dataset given the bindings in the current group graph pattern, the dataset and the active graph at this point in the query evaluation. No additional binding of variables occurs. The `NOT EXISTS` form translates into `fn:not(EXISTS{...})`.
    #
    # [126] NotExistsFunc           ::= 'NOT' 'EXISTS' GroupGraphPattern
    #
    # @example SPARQL Grammar
    #   PREFIX ex: <http://www.w3.org/2009/sparql/docs/tests/data-sparql11/negation#>
    #   SELECT ?animal { 
    #     ?animal a ex:Animal 
    #     FILTER NOT EXISTS { ?animal a ex:Insect } 
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((ex: <http://www.w3.org/2009/sparql/docs/tests/data-sparql11/negation#>))
    #    (project (?animal)
    #     (filter
    #      (notexists
    #       (bgp (triple ?animal a ex:Insect)))
    #      (bgp (triple ?animal a ex:Animal)))) )
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-abs
    # @see https://www.w3.org/TR/xpath-functions/#func-abs
    class NotExists < Operator::Unary
      include Evaluatable

      NAME = [:notexists]

      ##
      # Exvaluating this operator executes the query in the first operator passing in each existing bindings.
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @option options[RDF::Queryable] queryable
      #   queryable to execute, using bindings as an initial solution.
      # @return [RDF::Literal::Boolean] `true` or `false`
      def evaluate(bindings, **options)
        solutions = RDF::Query::Solutions(bindings)
        queryable = options[:queryable]
        operand(0).execute(queryable, solutions: solutions, **options).empty?
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @param [Boolean] top_level (true)
      #   Treat this as a top-level, generating SELECT ... WHERE {}
      # @return [String]
      def to_sparql(top_level: true, **options)
        "NOT EXISTS {\n" +
          operands.last.to_sparql(top_level: false, **options) +
          "\n}"
      end
    end # NotExists
  end # Operator
end; end # SPARQL::Algebra
