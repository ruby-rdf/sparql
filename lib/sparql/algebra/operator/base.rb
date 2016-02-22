module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `base` operator.
    #
    # @example
    #   (base <http://example.org/>
    #     (bgp (triple <a> <b> 123.0)))
    #
    # @see http://www.w3.org/TR/sparql11-query/#QSynIRI
    class Base < Binary
      include Query
      
      NAME = [:base]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Really a pass-through, as this is a syntactic object used for providing
      # context for relative URIs.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @yield  [solution]
      #   each matching solution, statement or boolean
      # @yieldparam  [RDF::Statement, RDF::Query::Solution, Boolean] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Queryable, RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, options = {}, &block)
        debug(options) {"Base #{operands.first}"}
        Operator.base_uri = operands.first
        queryable.query(operands.last, options.merge(depth: options[:depth].to_i + 1), &block)
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Return optimized query
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        operands.last.optimize
      end

      # Query results in a boolean result (e.g., ASK)
      # @return [Boolean]
      def query_yields_boolean?
        operands.last.query_yields_boolean?
      end

      # Query results statements (e.g., CONSTRUCT, DESCRIBE, CREATE)
      # @return [Boolean]
      def query_yields_statements?
        operands.last.query_yields_statements?
      end
    end # Base
  end # Operator
end; end # SPARQL::Algebra
