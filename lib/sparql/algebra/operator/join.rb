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
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      # @see    http://rdf.rubyforge.org/RDF/Query/Solution.html#merge-instance_method
      # @see    http://rdf.rubyforge.org/RDF/Query/Solution.html#compatible%3F-instance_method
      def execute(queryable, options = {})
        # Join(Ω1, Ω2) = { merge(μ1, μ2) | μ1 in Ω1 and μ2 in Ω2, and μ1 and μ2 are compatible }
        # eval(D(G), Join(P1, P2)) = Join(eval(D(G), P1), eval(D(G), P2))
        #
        # Generate solutions independently, merge based on solution compatibility
        debug("Join", options)
        solutions1 = operand(0).execute(queryable, options.merge(:depth => options[:depth].to_i + 1)) || {}
        debug("=>(left) #{solutions1.inspect}", options)
        solutions2 = operand(1).execute(queryable, options.merge(:depth => options[:depth].to_i + 1)) || {}
        debug("=>(right) #{solutions2.inspect}", options)
        @solutions = solutions1.map do |s1|
          solutions2.map { |s2| s2.merge(s1) if s2.compatible?(s1) }
        end.flatten.compact
        @solutions = RDF::Query::Solutions.new(@solutions)
        debug("=> #{@solutions.inspect}", options)
        @solutions
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
