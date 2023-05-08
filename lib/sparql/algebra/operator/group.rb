module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `group` operator.
    #
    # `group` takes either two or three operands. The first operand
    # is an array of grouped variables. The last operand is the
    # query to be grouped. If three operands are provided,
    # the second is an array of temporary bindings.
    #
    # [19]  GroupClause             ::= 'GROUP' 'BY' GroupCondition+
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://www.example.org>
    #   
    #   SELECT ?P (COUNT(?O) AS ?C)
    #   WHERE { ?S ?P ?O }
    #   GROUP BY ?P
    #
    # @example SSE
    #   (prefix
    #    ((: <http://www.example.org>))
    #    (project (?P ?C)
    #     (extend ((?C ??.0))
    #      (group (?P) ((??.0 (count ?O)))
    #       (bgp (triple ?S ?P ?O))))))
    #
    # @example SPARQL Grammar (HAVING aggregate)
    #   PREFIX : <http://www.example.org/>
    #   SELECT ?s (AVG(?o) AS ?avg)
    #   WHERE { ?s ?p ?o }
    #   GROUP BY ?s
    #   HAVING (AVG(?o) <= 2.0)
    #
    # @example SSE (HAVING aggregate)
    #   (prefix ((: <http://www.example.org/>))
    #    (project (?s ?avg)
    #     (filter (<= ??.1 2.0)
    #      (extend ((?avg ??.0))
    #       (group (?s) ((??.0 (avg ?o)) (??.1 (avg ?o)))
    #        (bgp (triple ?s ?p ?o)))))))
    #
    # @example SPARQL Grammar (non-trivial filters)
    #   PREFIX : <http://example.com/data/#>
    #   SELECT ?g (AVG(?p) AS ?avg) ((MIN(?p) + MAX(?p)) / 2 AS ?c)
    #   WHERE { ?g :p ?p . }
    #   GROUP BY ?g
    #
    # @example SSE (non-trivial filters)
    #   (prefix ((: <http://example.com/data/#>))
    #    (project (?g ?avg ?c)
    #     (extend ((?avg ??.0) (?c (/ (+ ??.1 ??.2) 2)))
    #      (group (?g)
    #             ((??.0 (avg ?p))
    #              (??.1 (min ?p))
    #              (??.2 (max ?p)))
    #       (bgp (triple ?g :p ?p)))) ))
    #
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    class Group < Operator
      include Query
      
      NAME = [:group]

      ##
      # Executes `query` with `queryable` and groups results based
      # on the first operand.
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
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlGroupAggregate
      def execute(queryable, **options, &block)
        debug(options) {"Group"}
        exprlist = operands.first
        query = operands.last
        aggregates = operands.length == 3 ? operand(1) : []
        solutions = queryable.query(query, **options.merge(depth: options[:depth].to_i + 1))

        groups = solutions.group_by do |solution|
          # Evaluate each exprlist operand to get groups where each key is a new solution
          # ListEval((expr1, ..., exprn), μ) returns a list (e1, ..., en), where ei = expri(μ) or error.
          soln = RDF::Query::Solution.new
          exprlist.each do |operand|
            begin
              if operand.is_a?(Array)
                # Form is [variable, expression]
                soln[operand.first] = operand.last.evaluate(solution,
                                                            queryable: queryable,
                                                            depth: options[:depth].to_i + 1,
                                                            **options)
              else
                # Form is variable
                soln[operand] = operand.evaluate(solution, queryable: queryable,
                                                           depth: options[:depth].to_i + 1,
                                                           **options)
              end
            rescue TypeError
              # Ignore expression
            end
          end
          soln
        end

        debug(options) {"=>(groups) #{groups.inspect}"}

        # Aggregate solutions in each group using aggregates to get solutions
        @solutions = RDF::Query::Solutions(groups.map do |group_soln, solns|
          aggregates.each do |(var, aggregate)|
            begin
              group_soln[var] = aggregate.aggregate(solns, **options)
            rescue TypeError
              # Ignored in output
            end
          end
          group_soln
        end)

        # If there exprlist is empty, make sure that's at least an empty solution
        if @solutions.empty? && exprlist.empty?
          soln = RDF::Query::Solution.new
          aggregates.each do |(var, aggregate)|
            begin
              soln[var] = aggregate.aggregate([], **options)
            rescue TypeError
              # Ignored in output
            end
          end
          @solutions << soln
        end

        debug(options) {"=>(solutions) #{@solutions.inspect}"}
        @solutions.each(&block) if block_given?
        @solutions
      end

      # It is an error for aggregates to project variables with a name already used in other aggregate projections, or in the WHERE clause.
      #
      # It is also an error to project ungrouped variables
      def validate!
        group_vars = operand(0).map {|v| Array(v).first}
        ext = first_ancestor(Extend)
        extend_vars = ext ? ext.operand(0).map(&:first).select {|v| v.is_a?(RDF::Query::Variable)} : []
        project = first_ancestor(Project)
        # If not projecting, were are effectively projecting all variables in the query
        project_vars = project ? project.operand(0) : operands.last.vars

        available_vars = (extend_vars + group_vars).compact

        # All variables must either be grouped or extended
        unless (project_vars - available_vars).empty?
          raise ArgumentError,
               "projecting ungrouped/extended variables: #{(project_vars.compact - available_vars.compact).to_sse}"
        end
        super
      end

      ##
      # The variables used in the extension.
      # Includes grouped variables and temporary, but not those in the query, itself
      #
      # @return [Hash{Symbol => RDF::Query::Variable}]
      def variables
        group_vars = operands.first

        aggregate_vars = (operands.length == 3 ? operand(1) : [])

        # Extract first element of each and merge it's variables
        (group_vars + aggregate_vars).
          map do  |o|
            v = Array(o).first
            v if v.is_a?(RDF::Query::Variable)
          end.compact.
          map(&:variables).
          inject({}) {|memo, h| memo.merge(h)}
      end

      ##
      # The variables used within the query
      #
      # @return [Hash{Symbol => RDF::Query::Variable}]
      def internal_variables
        operands.last.variables
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @param [Hash{String => Operator}] extensions
      #   Variable bindings
      # @param [Array<Operator>] filter_ops ([])
      #   Filter Operations
      # @return [String]
      def to_sparql(extensions: {}, filter_ops: [], **options)
        having_ops = []
        if operands.length > 2
          temp_bindings = operands[1].inject({}) {|memo, (var, op)| memo.merge(var => op)}
          # Replace extensions from temporary bindings
          temp_bindings.each do |var, op|
            # Update extensions using a temporarily bound variable with its binding
            extensions = extensions.inject({}) do |memo, (ext_var, ext_op)|
              if ext_op.is_a?(Operator)
                # Try to recursivley replace variable within operator
                new_op = ext_op.deep_dup.rewrite do |operand|
                  if operand.is_a?(Variable) && operand.to_sym == var.to_sym
                    op.dup
                  else
                    operand
                  end
                end
                memo.merge(ext_var.to_s => new_op)
              elsif ext_op.is_a?(Variable) && ext_op.to_sym == var.to_sym
                memo.merge(ext_var.to_s => op)
              else
                # Doesn't match this variable, so don't change
                memo.merge(ext_var.to_s => ext_op)
              end
            end

            # Filter ops using temporary bindinds are used for HAVING clauses
            filter_ops.each do |fop|
              having_ops << fop if fop.descendants.include?(var) && !having_ops.include?(fop)
            end
          end

          # If used in a HAVING clause, it's not also a filter
          filter_ops -= having_ops

          # Replace each operand in having using var with it's corresponding operation
          having_ops = having_ops.map do |op|
            op.dup.rewrite do |operand|
              # Rewrite based on temporary bindings
              temp_bindings.fetch(operand, operand)
            end
          end
        end
        operands.last.to_sparql(extensions: extensions,
                                group_ops: operands.first,
                                having_ops: having_ops,
                                **options)
      end
    end # Group
  end # Operator
end; end # SPARQL::Algebra
