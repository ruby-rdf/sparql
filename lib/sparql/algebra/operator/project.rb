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
    # @example SPARQL Grammar (Sub select)
    #   SELECT (1 AS ?X ) {
    #     SELECT (2 AS ?Y ) {}
    #   }
    #
    # @example SSE (Sub select)
    #   (project (?X)
    #    (extend ((?X 1))
    #     (project (?Y)
    #      (extend ((?Y 2))
    #       (bgp)))))
    #
    # @example SPARQL Grammar (filter projection)
    #   PREFIX : <http://www.example.org/>
    #   ASK {
    #     {SELECT (GROUP_CONCAT(?o) AS ?g) WHERE {
    #      :a :p1 ?o
    #     }}
    #     FILTER(?g = "1 22" || ?g = "22 1")
    #   }
    #
    # @example SSE (filter projection)
    #   (prefix ((: <http://www.example.org/>))
    #    (ask
    #     (filter
    #      (|| (= ?g "1 22") (= ?g "22 1"))
    #      (project (?g)
    #       (extend ((?g ??.0))
    #        (group () ((??.0 (group_concat ?o)))
    #         (bgp (triple :a :p1 ?o)))))) ))
    #
    # @see https://www.w3.org/TR/sparql11-query/#modProjection
    class Project < Operator::Binary
      include Query
      
      NAME = [:project]

      ##
      # Can only project in-scope variables.
      #
      # @return (see Algebra::Operator#initialize)
      def validate!
        if (group = descendants.detect {|o| o.is_a?(Group)})
          raise ArgumentError, "project * on group is illegal" if operands.first.empty?
          query_vars = operands.last.variables
          variables.keys.each do |v|
            raise ArgumentError,
              "projecting #{v.to_sse} not projected from group" unless
              query_vars.key?(v.to_sym)
          end
        end

        super
      end

      ##
      # The projected variables.
      #
      # @return [Hash{Symbol => RDF::Query::Variable}]
      def variables
        operands(1).inject({}) {|hash, o| hash.merge(o.variables)}
      end

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Reduces the result set to the variables listed in the first operand
      #
      # If the first operand is empty, this indicates a `SPARQL *`, and all in-scope variables are projected.
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
        @solutions = queryable.query(operands.last, **options.merge(depth: options[:depth].to_i + 1))
        @solutions.variable_names = self.variables.keys
        @solutions = @solutions.project(*(operands.first)) unless operands.first.empty?
        @solutions.each(&block) if block_given?
        @solutions
      end
    
      ##
      # In-scope variables for a select are limited to those projected.
      #
      # @return [Hash{Symbol => RDF::Query::Variable}]
      def variables
        in_scope = operands.first.empty? ?
          operands.last.variables.values :
          operands.first

        in_scope.inject({}) {|memo, v| memo.merge(v.variables)}
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
          content = "{#{content}}" unless content.start_with?('{') && content.end_with?('}')
          Operator.to_sparql(content, **options)
        else
          operands.last.to_sparql(project: vars, **options)
        end
      end
    end # Project
  end # Operator
end; end # SPARQL::Algebra
