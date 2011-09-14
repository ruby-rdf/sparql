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
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
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
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        debug("Union", options)
        solutions1 = operand(0).execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
        debug("=>(left) #{solutions1.inspect}", options)
        solutions2 = operand(1).execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
        debug("=>(right) #{solutions2.inspect}", options)
        @solutions = RDF::Query::Solutions.new(solutions1 + solutions2)
        debug("=> #{@solutions.inspect}", options)
        @solutions
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
        @operands = ops
        self
      end
    end # Union
  end # Operator
end; end # SPARQL::Algebra
