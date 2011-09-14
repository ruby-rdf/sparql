module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `slice` operator.
    #
    # @example
    #   (prefix ((: <http://example.org/ns#>))
    #     (slice 1 1
    #       (project (?v)
    #         (order (?v)
    #           (bgp (triple ??0 :num ?v))))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
    class Slice < Operator::Ternary
      include Query
      
      NAME = [:slice]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Returns a subset of the solutions resulting from executing
      # the third operand, an RDF::Queryable object by indexing in to the
      # result set by the amount specified in the first operand and limiting
      # the total number of solutions returned by the amount specified in the
      # second operand.
      #
      # If either the first or second operands are `:_`, they are not considered.
      #
      # @example
      #
      #   (slice 1 2 (bgp (triple ?s ?p ?o)))   # Returns at most two solutions starting with the second solution.
      #   (slice _ 2 (bgp (triple ?s ?p ?o)))   # Returns at most two solutions starting with the first solution.
      #   (slice 1 _ (bgp (triple ?s ?p ?o)))   # Returns all solution after the first.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        @solutions = operands.last. execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
        @solutions.offset(operands[0]) unless operands[0] == :_
        @solutions.limit(operands[1]) unless operands[1] == :_
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
    end # Slice
  end # Operator
end; end # SPARQL::Algebra
