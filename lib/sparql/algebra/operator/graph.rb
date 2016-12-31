module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `graph` operator.
    #
    # This is a wrapper to add a `graph_name` to the query, or an array of statements.
    #
    # @example of a query
    #   (prefix ((: <http://example/>))
    #     (graph ?g
    #       (bgp (triple ?s ?p ?o))))
    #
    # @example named set of statements
    #   (prefix ((: <http://example/>))
    #     (graph :g
    #       ((triple :s :p :o))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    class Graph < Operator::Binary
      include Query
      
      NAME = [:graph]
      ##
      # A `graph` is an RDF::Query with a graph_name. It can also be used as a container of statements or patterns, or other queryable operators (see GraphGraphPattern)
      #
      # @overload self.new(name, bgp)
      #   @param [RDF::Resource] name
      #   @param [RDF::Query] patterns
      #     A sub-query (bgp)
      # @overload self.new(name, bgp)
      #   @param [RDF::Resource] name
      #   @param [Operator] patterns
      #     A sub-query (GraphGraphPattern)
      # @overload self.new(name, patterns)
      #   @param [RDF::Resource] name
      #   @param [Array<RDF::Query::Pattern>] patterns
      #     Quads
      # @return [RDF::Query]
      def self.new(name, patterns, &block)
        case patterns
        when RDF::Query
          # Record that the argument as a (bgp) for re-serialization back to SSE
          RDF::Query.new(*patterns.patterns, graph_name: name, &block)
        when Operator
          super
        else
          RDF::Query.new(*patterns, graph_name: name, as_container: true, &block)
        end
      end

      ##
      # If the second operand is a Query operator:
      #   Executes this query on the given `queryable` graph or repository.
      #   Applies the given `graph_name` to the query, limiting the scope of the query to the specified `graph`, which may be an `RDF::URI` or `RDF::Query::Variable`.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, options = {}, &block)
        debug(options) {"Graph #{operands.first}"}
        graph_name, query = operands.first, operands.last
        @solutions = queryable.query(query, options.merge(graph_name: graph_name), &block)
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
      
      ##
      # Don't do any more rewriting
      # FIXME: if ooperator is JOIN, and rewritten sub-operators are queries, can do simple merge of sub-graphs
      # @return [SPARQL::Algebra::Expression] `self`
      def rewrite(&block)
        self
      end
    end # Graph
  end # Operator
end; end # SPARQL::Algebra
