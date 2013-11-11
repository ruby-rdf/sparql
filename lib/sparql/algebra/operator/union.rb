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
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        return @solutions = RDF::Query::Solutions::Enumerator.new do |yielder|
          self.execute(queryable, options) {|y| yielder << y}
        end unless block_given?

        debug(options) {"Union"}
        operands.each do |op|
          queryable.query(op, options.merge(:depth => options[:depth].to_i + 1)) do |solution|
            debug(options) {"(union) #{solution.to_hash.inspect}"}
            yield solution
          end
        end
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
