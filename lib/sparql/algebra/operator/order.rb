module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `order` operator.
    #
    # @example
    #   (prefix ((foaf: <http://xmlns.com/foaf/0.1/>))
    #     (project (?name)
    #       (order ((asc ?name))
    #         (bgp (triple ?x foaf:name ?name)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#modOrderBy
    class Order < Operator::Binary
      include Query
      
      NAME = [:order]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Orders a solution set returned by executing operand(1) using
      # an array of expressions and/or variables specified in operand(0)
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

        debug(options) {"Order"}
        @solutions = queryable.query(operands.last, options.merge(depth: options[:depth].to_i + 1)).order do |a, b|
          operand(0).inject(0) do |memo, op|
            debug(options) {"(order) #{op.inspect}"}
            memo = begin
              a_eval = op.evaluate(a, options.merge(queryable: queryable, depth: options[:depth].to_i + 1)) rescue nil
              b_eval = op.evaluate(b, options.merge(queryable: queryable, depth: options[:depth].to_i + 1)) rescue nil
              comp = Operator::Compare.evaluate(a_eval, b_eval).to_i
              comp = -comp if op.is_a?(Operator::Desc)
              comp
            end if memo == 0
            memo
          end
        end
        @solutions.each(&block) if block_given?
        @solutions
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
    end # Order
  end # Operator
end; end # SPARQL::Algebra
