module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `distinct` operator.
    #
    # @example
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example/>))
    #     (distinct
    #       (project (?v)
    #         (bgp (triple ?x ?p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#sparqlDistinct
    class Distinct < Operator::Unary
      include Query
      
      NAME = [:distinct]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Removes duplicate solutions from the solution set.
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
        @solutions = queryable.query(operands.last, depth: options[:depth].to_i + 1, **options).distinct
        @solutions.each(&block) if block_given?
        @solutions
      end
    end # Distinct
  end # Operator
end; end # SPARQL::Algebra
