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
    # @example
    #     (prefix ((: <http://example/>))
    #       (project (?w ?S)
    #         (extend ((?S ?.0))
    #           (group (?w) ((?.0 (sample ?v)))
    #             (leftjoin
    #               (bgp (triple ?s :p ?v))
    #               (bgp (triple ?s :q ?w)))))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
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
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlGroupAggregate
      def execute(queryable, options = {}, &block)
        debug(options) {"Group"}
        exprlist = operands.first
        query = operands.last
        aggregates = operands.length == 3 ? operand(1) : []
        solutions = queryable.query(query, options.merge(:depth => options[:depth].to_i + 1))

        groups = solutions.group_by do |solution|
          # Evaluate each exprlist operand to get groups where each key is a new solution
          # ListEval((expr1, ..., exprn), μ) returns a list (e1, ..., en), where ei = expri(μ) or error.
          soln = RDF::Query::Solution.new
          exprlist.each do |operand|
            begin
              if operand.is_a?(Array)
                # Form is [variable, expression]
                soln[operand.first] = operand.last.evaluate(solution,
                                                            options.merge(
                                                             :queryable => queryable,
                                                             :depth => options[:depth].to_i + 1))
              else
                # Form is variable
                soln[operand] = operand.evaluate(solution, options.merge(
                                                            :queryable => queryable,
                                                            :depth => options[:depth].to_i + 1))
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
              group_soln[var] = aggregate.aggregate(solns, options)
            rescue TypeError
              # Ignored in output
            end
          end
          group_soln
        end)

        # Make sure that's at least an empty solution
        @solutions << RDF::Query::Solution.new if @solutions.empty?

        debug(options) {"=>(solutions) #{@solutions.inspect}"}
        @solutions.each(&block) if block_given?
        @solutions
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # TODO
      #
      # @return [Group] `self`
      def optimize
        self
      end
    end # Group
  end # Operator
end; end # SPARQL::Algebra
