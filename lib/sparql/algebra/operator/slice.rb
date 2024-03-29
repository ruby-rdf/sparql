module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `slice` operator.
    #
    # [25]  LimitOffsetClauses      ::= LimitClause OffsetClause? | OffsetClause LimitClause?
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/ns#>
    #   
    #   SELECT ?v
    #   WHERE { :a ?p ?v }
    #   ORDER BY ?v
    #   OFFSET 100
    #   LIMIT 1
    #
    # @example SSE
    #   (prefix ((: <http://example.org/ns#>))
    #    (slice 100 1
    #     (project (?v)
    #      (order (?v)
    #       (bgp (triple :a ?p ?v))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
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
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)
        offset = operands[0] == :_ ? 0 : operands[0].to_i
        limit = operands[1] == :_ ? -1 : operands[1].to_i
        @solutions = operands.last. execute(queryable, **options.merge(depth: options[:depth].to_i + 1))
        @solutions.offset(operands[0]) unless operands[0] == :_
        @solutions.limit(operands[1]) unless operands[1] == :_
        @solutions.each(&block) if block_given?
        @solutions
      end

      ##
      #
      # Extracts OFFSET and LIMIT.
      #
      # @return [String]
      def to_sparql(**options)
        offset = operands[0].to_i unless operands[0] == :_
        limit = operands[1].to_i unless operands[1] == :_
        operands.last.to_sparql(offset: offset, limit: limit, **options)
      end
    end # Slice
  end # Operator
end; end # SPARQL::Algebra
