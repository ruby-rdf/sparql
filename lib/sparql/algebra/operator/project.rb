module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `project` operator.
    #
    # [9] SelectClause ::= 'SELECT' ( 'DISTINCT' | 'REDUCED' )?  ( ( Var | ( '(' Expression 'AS' Var ')' ) )+ | '*' )
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example/>
    #   SELECT ?v  { 
    #     ?s :p ?v . 
    #     FILTER (?v = 2)
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (project (?v)
    #     (filter (= ?v 2)
    #      (bgp (triple ?s :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#modProjection
    class Project < Operator::Binary
      include Query
      
      NAME = [:project]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Reduces the result set to the variables listed in the first operand
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
        @solutions = queryable.query(operands.last, depth: options[:depth].to_i + 1, **options)
        @solutions = @solutions.project(*(operands.first))
        @solutions.each(&block) if block_given?
        @solutions
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # Extracts projections
      #
      # @param [Boolean] distinct (false)
      # @return [String]
      def to_sparql(**options)
        vars = operands[0].empty? ? [:*] : operands[0]
        operands.last.to_sparql(project: vars, **options)
      end
    end # Project
  end # Operator
end; end # SPARQL::Algebra
