module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `leftjoin` operator.
    #
    # [57]  OptionalGraphPattern    ::= 'OPTIONAL' GroupGraphPattern
    #
    # @example SPARQL Grammar
    #   PREFIX :    <http://example/>
    #   SELECT * { 
    #     ?x :p ?v .
    #     OPTIONAL { 
    #       ?y :q ?w .
    #       FILTER(?v=2)
    #     }
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #     (leftjoin
    #       (bgp (triple ?x :p ?v))
    #       (bgp (triple ?y :q ?w))
    #       (= ?v 2)))
    #
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
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
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      # @see    https://ruby-rdf.github.io/rdf/RDF/Query/Solution#merge-instance_method
      # @see    https://ruby-rdf.github.io/rdf/RDF/Query/Solution#compatible%3F-instance_method
      def execute(queryable, **options, &block)
        filter = operand(2)

        raise ArgumentError,
          "leftjoin operator accepts at most two arguments with an optional filter" if
          operands.length < 2 || operands.length > 3

        debug(options) {"LeftJoin"}
        left = queryable.query(operand(0), **options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"=>(leftjoin left) #{left.inspect}"}

        right = queryable.query(operand(1), **options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"=>(leftjoin right) #{right.inspect}"}

        # LeftJoin(Ω1, Ω2, expr) =
        @solutions = RDF::Query::Solutions()
        left.each do |s1|
          load_left = true
          right.each do |s2|
            s = s2.merge(s1)
            # Re-bind to bindings, if defined, as they might not be found in solution
            options[:bindings].each_binding do |name, value|
              s[name] = value if filter.variables.include?(name)
            end if options[:bindings] && filter.respond_to?(:variables)

            # See https://github.com/w3c/rdf-tests/pull/83#issuecomment-1324220844 for @afs's discussion of the simplified/not-simplified issue.
            #
            # The difference is when simplification is applied. It matters for OPTIONAL because OPTIONAL { ... FILTER(...) } puts the filter into the LeftJoin expressions. In LeftJoin, the FILTER can see the left-hand-side variables. (SQL: LEFT JOIN ... ON ...)
            # 
            # For OPTIONAL { { ... FILTER(...) } }, the inner part is Join({}, {.... FILTER }).
            # 
            # if simplify happens while coming back up the tree generating algebra operations, it removes the join i.e. the inner of {{ }}, and passes "... FILTER()" to the OPTIONAL. The effect of the extra nesting in {{ }} is lost and it exposes the filter to the OPTIONAL rule.
            # 
            # if simplification happens as a step after the whole algebra is converted, this does not happen. Compiling the OPTIONAL see a join and the filter is not at the top level of the OPTIONAl block and so not handled in the LeftJoin.
            # 
            # Use case:
            # 
            # # Include name if person over 18
            # SELECT *
            # { ?person :age ?age 
            #    OPTIONAL { ?person :name ?name. FILTER(?age > 18) }
            # }
            # Hindsight: a better syntax would be call out if the filter needed access to the LHS.
            # 
            # OPTIONAL FILTER(....) { }
            # 
            # But we are where we are.
            # 
            # (a "no conditions on LeftJoin" approach would mean users having to duplicate parts of their query - possibly quite large parts.)
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
      # Optimizes this query.
      #
      # If optimize operands, and if the first two operands are both Queries, replace
      # with the unique sum of the query elements
      #
      # @return [Object] a copy of `self`
      # @see SPARQL::Algebra::Expression#optimize
      # FIXME
      def optimize(**options)
        lhs, rhs, expr = operands.map {|o| o.optimize(**options) }
        expr = nil if expr.respond_to?(:true?) && expr.true?

        if lhs.empty? && rhs.empty?
          RDF::Query.new  # Empty query, expr doesn't matter
        elsif rhs.empty?
          # Expression doesn't matter, just use the first operand
          lhs
        elsif lhs.empty?
          # Result is the filter of the second operand if there is an expression
          # FIXME: doesn't seem to work
          #expr ? Filter.new(expr, rhs) : rhs
          self.dup
        else
          expr ? LeftJoin.new(rhs, lhs, expr) : LeftJoin.new(lhs, rhs)
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @param [Boolean] top_level (true)
      #   Treat this as a top-level, generating SELECT ... WHERE {}
      # @param [Hash{String => Operator}] extensions
      #   Variable bindings
      # @param [Array<Operator>] filter_ops ([])
      #   Filter Operations
      # @return [String]
      def to_sparql(top_level: true, filter_ops: [], extensions: {}, **options)
        str = "{\n" + operands[0].to_sparql(top_level: false, extensions: {}, **options)
        str << 
          "\nOPTIONAL {\n" +
          operands[1].to_sparql(top_level: false, extensions: {}, **options)
        case operands[2]
        when SPARQL::Algebra::Operator::Exprlist
          operands[2].operands.each do |op|
            str << "\nFILTER (" + op.to_sparql(**options) + ")"
          end
        when nil
        else
          str << "\nFILTER (" + operands[2].to_sparql(**options) + ")"
        end
        str << "\n}}"
        top_level ? Operator.to_sparql(str, filter_ops: filter_ops, extensions: extensions, **options) : str
      end
    end # LeftJoin
  end # Operator
end; end # SPARQL::Algebra
