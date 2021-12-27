module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `project` operator.
    #
    # [9] SelectClause ::= 'SELECT' ( 'DISTINCT' | 'REDUCED' )?  ( ( Var | ( '(' Expression 'AS' Var ')' ) )+ | '*' )
    #
    # ## Basic Projection
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
    # ## Sub select
    #
    # @example SPARQL Grammar
    #   SELECT (1 AS ?X ) {
    #     SELECT (2 AS ?Y ) {}
    #   }
    #
    # @example SSE
    #   (project (?X)
    #    (extend ((?X 1))
    #     (project (?Y)
    #      (extend ((?Y 2))
    #       (bgp)))))
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
      # If there are already extensions or filters, then this is a sub-select.
      #
      # @return [String]
      def to_sparql(**options)
        vars = operands[0].empty? ? [:*] : operands[0]
        if options[:extensions] || options[:filter_ops] || options[:project]
          # Any of these options indicates we're in a sub-select
          opts = options.dup.delete_if {|k,v| %I{extensions filter_ops project}.include?(k)}
          content = operands.last.to_sparql(project: vars, **opts)
          Operator.to_sparql(content, **options)
        else
          operands.last.to_sparql(project: vars, **options)
        end
      end
    end # Project
  end # Operator
end; end # SPARQL::Algebra
