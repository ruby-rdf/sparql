module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `exists` operator.
    #
    # There is a filter operator EXISTS that takes a graph pattern. EXISTS returns `true`/`false` depending on whether the pattern matches the dataset given the bindings in the current group graph pattern, the dataset and the active graph at this point in the query evaluation. No additional binding of variables occurs. The `NOT EXISTS` form translates into `fn:not(EXISTS{...})`.
    #
    # [125] ExistsFunc              ::= 'EXISTS' GroupGraphPattern
    #
    # @example SPARQL Grammar
    #   PREFIX :    <http://example/>
    #   SELECT *
    #   WHERE {
    #     ?set a :Set .
    #     FILTER EXISTS { ?set :member 9 }
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (filter
    #     (exists (bgp (triple ?set :member 9)))
    #     (bgp (triple ?set a :Set))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-filter-exists
    class Exists < Operator::Unary
      include Evaluatable

      NAME = [:exists]

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
        queryable = options[:queryable]
        !operand(0).execute(queryable, solutions: RDF::Query::Solutions(bindings),
                                       depth: options[:depth].to_i + 1,
                                       **options).empty?
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @param [Boolean] top_level (true)
      #   Treat this as a top-level, generating SELECT ... WHERE {}
      # @return [String]
      def to_sparql(top_level: true, **options)
        "EXISTS {\n" +
          operands.last.to_sparql(top_level: false, **options) +
          "\n}"
      end
    end # Exists
  end # Operator
end; end # SPARQL::Algebra
