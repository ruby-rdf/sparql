module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `base` operator.
    #
    # @example
    #   (base <http://example.org/>
    #     (bgp (triple <a> <b> 123.0)))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#QSynIRI
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
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        debug("Base #{operands.first}", options)
        @solutions = operands.last.execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
        debug("=> #{@solutions.inspect}", options)
        @solutions
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
    end # Base
  end # Operator
end; end # SPARQL::Algebra
