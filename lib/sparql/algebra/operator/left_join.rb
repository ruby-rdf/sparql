module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `leftjoin` operator.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (leftjoin
    #       (bgp (triple ?x :p ?v))
    #       (bgp (triple ?y :q ?w))
    #       (= ?v 2)))
    #
    # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    class LeftJoin < Operator
      include Query
      
      NAME = [:leftjoin]

      ##
      # Executes each operand with `queryable` and performs the `leftjoin` operation
      # by adding every solution from the left, merging compatible solutions from the right
      # that match an optional filter.
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
      # @see    http://rdf.rubyforge.org/RDF/Query/Solution.html#merge-instance_method
      # @see    http://rdf.rubyforge.org/RDF/Query/Solution.html#compatible%3F-instance_method
      def execute(queryable, options = {}, &block)
        filter = operand(2)

        debug(options) {"LeftJoin"}
        left = queryable.query(operand(0), options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"=>(leftjoin left) #{left.inspect}"}

        right = queryable.query(operand(1), options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"=>(leftjoin right) #{right.inspect}"}

        # LeftJoin(Ω1, Ω2, expr) =
        @solutions = RDF::Query::Solutions()
        left.each do |s1|
          load_left = true
          right.each do |s2|
            s = s2.merge(s1)
            expr = filter ? boolean(filter.evaluate(s)).true? : true rescue false
            debug(options) {"===>(evaluate) #{s.inspect}"} if filter

            if expr && s1.compatible?(s2)
              # { merge(μ1, μ2) | μ1 in Ω1 and μ2 in Ω2, and μ1 and μ2 are compatible and expr(merge(μ1, μ2)) is true }
              debug(options) {"=>(merge s1 s2) #{s.inspect}"}
              @solutions << s
              load_left = false   # Left solution added one or more times due to merge
            end
          end
          if load_left
            debug(options) {"=>(add) #{s1.inspect}"}
            @solutions << s1
          end
        end
        
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
      # If optimize operands, and if the first two operands are both Queries, replace
      # with the unique sum of the query elements
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        ops = operands.map {|o| o.optimize }.select {|o| o.respond_to?(:empty?) && !o.empty?}
        expr = ops.pop unless ops.last.executable?
        expr = nil if expr.respond_to?(:true?) && expr.true?
        
        # ops now is one or two executable operators
        # expr is a filter expression, which may have been optimized to 'true'
        case ops.length
        when 0
          RDF::Query.new  # Empty query, expr doesn't matter
        when 1
          expr ? Filter.new(expr, ops.first) : ops.first
        else
          expr ? LeftJoin(ops[0], ops[1], expr) : LeftJoin(ops[0], ops[1])
        end
      end
    end # LeftJoin
  end # Operator
end; end # SPARQL::Algebra
