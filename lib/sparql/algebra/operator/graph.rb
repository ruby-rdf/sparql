# FIXME: This depends on an update to RDF::Query#execute to be able to pass the context as an option.
module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `graph` operator.
    #
    # This is a wrapper to add a `context` to the query.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (graph ?g
    #       (bgp (triple ?s ?p ?o))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
    class Graph < Operator::Binary
      include Query
      
      NAME = [:graph]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Applies the given `context` to the query, limiting the scope of the query to the specified `context`, which may be an `RDF::URI` or `RDF::Query::Variable`.
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
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {}, &block)
        debug(options) {"Graph #{operands.first}"}
        context, query = operands.first, operands.last
        @solutions = queryable.query(query, options.merge(:context => context), &block)
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
      # @return [SPARQL::Algebra::Expression] `self`
      def rewrite(&block)
        self
      end
    end # Graph
  end # Operator
end; end # SPARQL::Algebra
