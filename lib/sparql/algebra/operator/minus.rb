module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `minus` operator.
    #
    # [66]  MinusGraphPattern       ::= 'MINUS' GroupGraphPattern
    #
    # @example SPARQL Grammar
    #   SELECT * { ?s ?p ?o MINUS { ?s ?q ?v } }
    #
    # @example SSE
    #   (minus
    #    (bgp
    #     (triple ?s ?p ?o))
    #    (bgp (triple ?s ?q ?v)))
    #
    # @example SPARQL Grammar (inline filter)
    #   PREFIX :    <http://example/>
    #   SELECT (?s1 AS ?subset) (?s2 AS ?superset)
    #   WHERE {
    #       ?s2 a :Set .
    #       ?s1 a :Set .
    #       FILTER(?s1 != ?s2)
    #       MINUS {
    #           ?s1 a :Set .
    #           ?s2 a :Set .
    #           FILTER(?s1 != ?s2)
    #       }
    #   }
    # 
    # @example SSE (inline filter)
    #   (prefix ((: <http://example/>))
    #    (project (?subset ?superset)
    #     (extend ((?subset ?s1) (?superset ?s2))
    #      (filter (!= ?s1 ?s2)
    #       (minus
    #        (bgp (triple ?s2 a :Set) (triple ?s1 a :Set))
    #        (filter (!= ?s1 ?s2)
    #         (bgp
    #          (triple ?s1 a :Set)
    #          (triple ?s2 a :Set))))))))
    #
    # @see https://www.w3.org/TR/xpath-functions/#func-numeric-unary-minus
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    class Minus < Operator::Binary
      include Query

      NAME = :minus

      ##
      # Executes each operand with `queryable` and performs the `join` operation
      # by creating a new solution set containing the `merge` of all solutions
      # from each set that are `compatible` with each other.
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
      # @see    https://www.w3.org/TR/2013/REC-sparql11-query-20130321/#defn_algMinus
      # @see    https://www.w3.org/TR/2013/REC-sparql11-query-20130321/#negation
      def execute(queryable, **options, &block)
        # Let Ω1 and Ω2 be multisets of solution mappings. We define:
        # 
        # Minus(Ω1, Ω2) = { μ | μ in Ω1 . ∀ μ' in Ω2, either μ and μ' are not compatible or dom(μ) and dom(μ') are disjoint }
        # 
        # card[Minus(Ω1, Ω2)](μ) = card[Ω1](μ)
        debug(options) {"Minus"}
        left = queryable.query(operand(0), **options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"(minus left) #{left.inspect}"}
        right = queryable.query(operand(1), **options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"(minus right) #{right.inspect}"}
        @solutions = left.minus(right)
        @solutions.each(&block) if block_given?
        @solutions
      end
      
      ##
      # Optimizes this query.
      #
      # Groups of one graph pattern (not a filter) become join(Z, A) and can be replaced by A.
      # The empty graph pattern Z is the identity for join:
      #   Replace join(Z, A) by A
      #   Replace join(A, Z) by A
      #
      # @return [self]
      # @see SPARQL::Algebra::Expression#optimize!
      def optimize!(**options)
        ops = operands.map {|o| o.optimize(**options) }.reject {|o| o.respond_to?(:empty?) && o.empty?}
        @operands = ops
        self
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @param [Hash{String => Operator}] extensions
      #   Variable bindings
      # @param [Array<Operator>] filter_ops ([])
      #   Filter Operations
      # @param [Boolean] top_level (true)
      #   Treat this as a top-level, generating SELECT ... WHERE {}
      # @return [String]
      def to_sparql(top_level: true, filter_ops: [], extensions: {}, **options)
        lhs, *rhs = operands
        str = "{\n" + lhs.to_sparql(top_level: false, extensions: {}, **options)

        # Any accrued filters go here.
        filter_ops.each do |op|
          str << "\nFILTER (#{op.to_sparql(**options)}) ."
        end

        rhs.each do |minus|
          str << "\nMINUS {\n"
          str << minus.to_sparql(top_level: false, extensions: {}, **options)
          str << "\n}"
        end
        str << "}"
        top_level ? Operator.to_sparql(str, extensions: extensions, **options) : str
      end
    end # Minus
  end # Operator
end; end # SPARQL::Algebra
