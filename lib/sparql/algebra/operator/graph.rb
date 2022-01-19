module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `graph` operator.
    #
    # This is a wrapper to add a `graph_name` to the query, or an array of statements.
    #
    # [58]  GraphGraphPattern       ::= 'GRAPH' VarOrIri GroupGraphPattern
    #
    # @example SPARQL Grammar (query)
    #   PREFIX : <http://example/> 
    #   SELECT * { 
    #       GRAPH ?g { ?s ?p ?o }
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (graph ?g
    #     (bgp (triple ?s ?p ?o))))
    #
    # @example SPARQL Grammar (named set of statements)
    #   PREFIX : <http://example/> 
    #   SELECT * { 
    #       GRAPH :g { :s :p :o }
    #   }
    #
    # @example SSE (named set of statements)
    #   (prefix ((: <http://example/>))
    #    (graph :g
    #     (bgp (triple :s :p :o))))
    #
    # @example SPARQL Grammar (syntax-graph-05.rq)
    #   PREFIX : <http://example.org/>
    #   SELECT *
    #   WHERE
    #   {
    #     :x :p :z
    #     GRAPH ?g { :x :b ?a . GRAPH ?g2 { :x :p ?x } }
    #   }
    #
    # @example SSE (syntax-graph-05.rq)
    #   (prefix ((: <http://example.org/>))
    #    (join
    #     (bgp (triple :x :p :z))
    #     (graph ?g
    #      (join
    #       (bgp (triple :x :b ?a))
    #       (graph ?g2
    #        (bgp (triple :x :p ?x)))))))
    #
    # @example SPARQL Grammar (pp06.rq)
    #   prefix ex:	<http://www.example.org/schema#>
    #   prefix in:	<http://www.example.org/instance#>
    #   
    #   select ?x where {
    #     graph ?g {in:a ex:p1/ex:p2 ?x}
    #   }
    #
    # @example SSE (syntax-graph-05.rq)
    #   (prefix ((ex: <http://www.example.org/schema#>)
    #            (in: <http://www.example.org/instance#>))
    #    (project (?x)
    #     (graph ?g
    #      (path in:a (seq ex:p1 ex:p2) ?x))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
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
      def self.new(name, patterns, **options, &block)
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
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)
        debug(options) {"Graph #{operands.first}"}
        graph_name, query = operands.first, operands.last
        @solutions = queryable.query(query, graph_name: graph_name, **options, &block)
      end

      ##
      # Don't do any more rewriting
      # @return [SPARQL::Algebra::Expression] `self`
      def rewrite(&block)
        self
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @param [Boolean] top_level (true)
      #   Treat this as a top-level, generating SELECT ... WHERE {}
      # @return [String]
      def to_sparql(top_level: true, **options)
        query = operands.last.to_sparql(top_level: false, **options)
        # Paths don't automatically get braces.
        query = "{\n#{query}\n}" unless query.start_with?('{')
        str = "GRAPH #{operands.first.to_sparql(**options)} " + query
        top_level ? Operator.to_sparql(str, **options) : str
      end
    end # Graph
  end # Operator
end; end # SPARQL::Algebra
