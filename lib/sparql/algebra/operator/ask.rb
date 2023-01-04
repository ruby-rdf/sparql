module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `ask` operator.
    #
    # Applications can use the ASK form to test whether or not a query pattern has a solution. No information is returned about the possible query solutions, just whether or not a solution exists.
    #
    # [12]  AskQuery                ::= 'ASK' DatasetClause* WhereClause ValuesClause
    #
    # @example SPARQL Query
    #   PREFIX :    <http://example/>
    #   ASK  { :x :p  ?x }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #     (ask
    #       (bgp (triple :x :p ?x))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#ask
    class Ask < Operator::Unary
      include Query
      
      NAME = [:ask]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Returns true if any solutions are found, false otherwise.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @yield  [RDF::Literal::Boolean]
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Literal::Boolean]\
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options)
        debug(options) {"Ask #{operands.first}"}
        res = boolean(!queryable.query(operands.last, **options.merge(depth: options[:depth].to_i + 1)).empty?)
        yield res if block_given?
        res
      end

      # Query results in a boolean result (e.g., ASK)
      # @return [Boolean]
      def query_yields_boolean?
        true
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        "ASK\n" +
        operands.first.to_sparql(top_level: true, project: nil, **options)
      end
    end # Ask
  end # Operator
end; end # SPARQL::Algebra
