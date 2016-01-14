module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `union` operator.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (union
    #       (bgp (triple ?s ?p ?o))
    #       (graph ?g
    #         (bgp (triple ?s ?p ?o)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    class Union < Operator::Binary
      include Query
      
      NAME = [:union]

      ##
      # Executes each operand with `queryable` and performs the `union` operation
      # by creating a new solution set consiting of all solutions from both operands.
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
      def execute(queryable, options = {}, &block)
        debug(options) {"Union"}
        @solutions = RDF::Query::Solutions(operands.inject([]) do |memo, op|
          solns = op.execute(queryable, options.merge(depth: options[:depth].to_i + 1))
          debug(options) {"=> (op) #{solns.inspect}"}
          memo + solns
        end)
        debug(options) {"=> #{@solutions.inspect}"}
        @solutions.each(&block) if block_given?
        @solutions
      end

      # The same blank node label cannot be used in two different basic graph patterns in the same query
      def validate!
        left_nodes, right_nodes = operand(0).ndvars, operand(1).ndvars

        unless (left_nodes.compact & right_nodes.compact).empty?
          raise ArgumentError,
               "sub-operands share non-distinguished variables: #{(left_nodes.compact & right_nodes.compact).to_sse}"
        end
        super
      end

      ##
      # Returns an optimized version of this query.
      #
      # Optimize operands and remove any which are empty.
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        ops = operands.map {|o| o.optimize }.select {|o| o.respond_to?(:empty?) && !o.empty?}
        @operands = ops
        self
      end
    end # Union
  end # Operator
end; end # SPARQL::Algebra
