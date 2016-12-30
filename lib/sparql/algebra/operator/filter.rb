module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `filter` operator.
    #
    # @example
    #   (select (?v)
    #     (project (?v)
    #       (filter (= ?v 2)
    #         (bgp (triple ?s <http://example/p> ?v)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#evaluation
    class Filter < Operator::Binary
      include Query
      
      NAME = [:filter]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Then it passes each solution through one or more filters and removes
      # those that evaluate to false or generate a _TypeError_.
      #
      # Note that the last operand returns a solution set, while the first
      # is an expression. This may be a variable, simple expression,
      # or exprlist.
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
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      # @see    http://www.w3.org/TR/sparql11-query/#ebv
      def execute(queryable, options = {}, &block)
        debug(options) {"Filter #{operands.first.to_sxp}"}
        opts = options.merge(queryable: queryable, depth: options[:depth].to_i + 1)
        @solutions = RDF::Query::Solutions()
        queryable.query(operands.last, options.merge(depth: options[:depth].to_i + 1)) do |solution|
          begin
            pass = boolean(operands.first.evaluate(solution, opts)).true?
            debug(options) {"(filter) #{pass.inspect} #{solution.to_h.inspect}"}
            @solutions << solution if pass
          rescue
            debug(options) {"(filter) rescue(#{$!}): #{solution.to_h.inspect}"}
          end
        end
        @solutions.each(&block) if block_given?
        @solutions
      end

      # If filtering a join of two BGPs (having the same graph name), don't worry about validating, for shared ndvars, anyway,
      #
      #       (filter (regex ?homepage "^http://example.org/" "")
      #         (join
      #           (bgp (triple ??who :homepage ?homepage))
      #           (bgp (triple ??who :schoolHomepage ?schoolPage))))))
      #
      # is legitimate
      def validate!
        unless (join = operands.last).is_a?(Join) &&
                join.operands.all? {|op| op.is_a?(RDF::Query)} &&
                join.operands.map(&:graph_name).uniq.length == 1
          operands.last.validate!
        end
        self
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
    end # Filter
  end # Operator
end; end # SPARQL::Algebra
