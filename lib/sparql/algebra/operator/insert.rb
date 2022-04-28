module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `insertData` operator.
    #
    # The INSERT operation is a form of the DELETE/INSERT operation having no DELETE section
    #
    # [43]  InsertClause            ::= 'INSERT' QuadPattern
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/> 
    #   INSERT { ?s ?p "q" }
    #   WHERE { ?s ?p ?o }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (update
    #     (modify (bgp (triple ?s ?p ?o))
    #      (insert ((triple ?s ?p "q"))))))
    #
    # @see https://www.w3.org/TR/sparql11-update/#insert
    class Insert < Operator::Unary
      include SPARQL::Algebra::Update

      NAME = [:insert]

      ##
      # Executes this upate on the given `writable` graph or repository.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to write
      # @param  [RDF::Query::Solutions] solutions
      #   Solution to map to patterns for this operation
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @option options [Boolean] debug
      #   Query execution debugging
      # @return [RDF::Queryable]
      #   Returns queryable.
      # @raise [IOError]
      #   If `from` does not exist, unless the `silent` operator is present
      # @see    https://www.w3.org/TR/sparql11-update/
      def execute(queryable, solutions: nil, **options)
        # Only binds the first solution
        solution = solutions.is_a?(RDF::Query::Solutions) ? solutions.first : solutions
        debug(options) {"Insert"}
        patterns = operand.inject([]) do |memo, op|
          if op.respond_to?(:statements)
            memo += op.statements.to_a
          else
            memo << op
          end
          memo
        end
        patterns.each do |pattern|
          pattern = pattern.dup.bind(solution)
          debug(options) {"Insert pattern #{pattern.to_sse}"}
          # Only insert bound or constant patterns
          queryable.insert(RDF::Statement.from(pattern)) if pattern.bound? || pattern.constant?
        end
        queryable
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        "INSERT {\n" +
          operands.first.to_sparql(delimiter: " .\n", **options) +
          "\n}"
      end
    end # Insert
  end # Operator
end; end # SPARQL::Algebra
