module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `join` operator.
    #
    # [54]	GroupGraphPatternSub	::=	TriplesBlock? (GraphPatternNotTriples "."? TriplesBlock? )*
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example/> 
    #   SELECT * { 
    #      ?s ?p ?o
    #      GRAPH ?g { ?s ?q ?v }
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #     (join
    #       (bgp (triple ?s ?p ?o))
    #       (graph ?g
    #         (bgp (triple ?s ?q ?v)))))
    #
    # @example SPARQL Grammar (inline filter)
    #   PREFIX : <http://xmlns.com/foaf/0.1/>
    #   ASK {
    #     :who :homepage ?homepage 
    #     FILTER REGEX(?homepage, "^http://example.org/") 
    #     :who :schoolHomepage ?schoolPage
    #   }
    # 
    # @example SSE (inline filter)
    #   (prefix ((: <http://xmlns.com/foaf/0.1/>))
    #    (ask
    #     (filter (regex ?homepage "^http://example.org/")
    #      (join
    #       (bgp (triple :who :homepage ?homepage))
    #       (bgp (triple :who :schoolHomepage ?schoolPage))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    class Join < Operator::Binary
      include Query
      
      NAME = [:join]

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
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      # @see    https://ruby-rdf.github.io/rdf/RDF/Query/Solution#merge-instance_method
      # @see    https://ruby-rdf.github.io/rdf/RDF/Query/Solution#compatible%3F-instance_method
      def execute(queryable, **options, &block)
        # Join(Ω1, Ω2) = { merge(μ1, μ2) | μ1 in Ω1 and μ2 in Ω2, and μ1 and μ2 are compatible }
        # eval(D(G), Join(P1, P2)) = Join(eval(D(G), P1), eval(D(G), P2))
        #
        # Generate solutions independently, merge based on solution compatibility
        debug(options) {"Join #{operands.to_sse}"}
 
        left = queryable.query(operand(0), **options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"(join)=>(left) #{left.map(&:to_h).to_sse}"}

        right = queryable.query(operand(1), **options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"(join)=>(right) #{right.map(&:to_h).to_sse}"}

        @solutions = RDF::Query::Solutions(left.map do |s1|
          right.map { |s2| s2.merge(s1) if s2.compatible?(s1) }
        end.flatten.compact)
        debug(options) {"(join)=> #{@solutions.map(&:to_h).to_sse}"}
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
      # Groups of one graph pattern (not a filter) become join(Z, A) and can be replaced by A.
      # The empty graph pattern Z is the identity for join:
      #   Replace join(Z, A) by A
      #   Replace join(A, Z) by A
      #
      # @return [Join, RDF::Query] `self`
      # @return [self]
      # @see SPARQL::Algebra::Expression#optimize
      def optimize(**options)
        ops = operands.map {|o| o.optimize(**options) }.reject {|o| o.respond_to?(:empty?) && o.empty?}
        case ops.length
        when 0
          SPARQL::Algebra::Expression[:bgp]
        when 1
          ops.first
        else
          self.class.new(ops)
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
        # If this is top-level, and the last operand is a Table (values), put the values at the outer-level
        str = "{\n" + operands.first.to_sparql(top_level: false, extensions: {}, **options)

        # Any accrued filters go here.
        filter_ops.each do |op|
          str << "\nFILTER (#{op.to_sparql(**options)}) ."
        end

        if top_level && operands.last.is_a?(Table)
          str << "\n}"
          options = options.merge(values_clause: operands.last)
        else
          str << "\n{\n" + operands.last.to_sparql(top_level: false, extensions: {}, **options) + "\n}\n}"
        end

        top_level ? Operator.to_sparql(str, extensions: extensions, **options) : str
      end
    end # Join
  end # Operator
end; end # SPARQL::Algebra
