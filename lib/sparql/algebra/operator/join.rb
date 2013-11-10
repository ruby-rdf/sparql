module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `join` operator.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (join
    #       (bgp (triple ?s ?p ?o))
    #       (graph ?g
    #         (bgp (triple ?s ?q ?v)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
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
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      # @see    http://rdf.rubyforge.org/RDF/Query/Solution.html#merge-instance_method
      # @see    http://rdf.rubyforge.org/RDF/Query/Solution.html#compatible%3F-instance_method
      def execute(queryable, options = {})
        return @solutions = RDF::Query::Solutions::Enumerator.new do |yielder|
          self.execute(queryable, options) {|y| yielder << y}
        end unless block_given?

        # Join(Ω1, Ω2) = { merge(μ1, μ2) | μ1 in Ω1 and μ2 in Ω2, and μ1 and μ2 are compatible }
        # eval(D(G), Join(P1, P2)) = Join(eval(D(G), P1), eval(D(G), P2))
        #
        # Generate solutions independently, merge based on solution compatibility
        debug(options) {"Join"}
        right = operand(1).execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
        debug(options) {"(join)=>(right) #{right.inspect}"}

        operand(0).execute(queryable, options.merge(:depth => options[:depth].to_i + 1)) do |sl|
          right.each do |sr|
            debug(options) {"(join)==>(merge) #{[sl,sr].inspect}"} if sr.compatible?(sl)
            yield sl.merge(sr) if sr.compatible?(sl)
          end
        end
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Groups of one graph pattern (not a filter) become join(Z, A) and can be replaced by A.
      # The empty graph pattern Z is the identity for join:
      #   Replace join(Z, A) by A
      #   Replace join(A, Z) by A
      #
      # @return [Join, RDF::Query] `self`
      def optimize
        ops = operands.map {|o| o.optimize }.select {|o| o.respond_to?(:empty?) && !o.empty?}
        @operands = ops
        self
      end
    end # Join
  end # Operator
end; end # SPARQL::Algebra
