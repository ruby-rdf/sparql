module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `delete` operator.
    #
    # The DELETE operation is a form of the DELETE/INSERT operation having no INSERT section
    #
    # [42]  DeleteClause            ::= 'DELETE' QuadPattern
    #
    # @example SPARQL Grammar
    #   PREFIX     : <http://example.org/> 
    #   PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
    #   
    #   DELETE { ?s ?p ?o }
    #   WHERE  { :a foaf:knows ?s . ?s ?p ?o }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>)
    #            (foaf: <http://xmlns.com/foaf/0.1/>))
    #    (update
    #     (modify
    #      (bgp
    #       (triple :a foaf:knows ?s)
    #       (triple ?s ?p ?o))
    #      (delete ((triple ?s ?p ?o))))))
    #
    # @see https://www.w3.org/TR/sparql11-update/#delete
    class Delete < Operator::Unary
      include SPARQL::Algebra::Update

      NAME = [:delete]

      ##
      # Executes this upate on the given `writable` graph or repository.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to write
      # @param  [RDF::Query::Solutions] solutions
      #   Solutions to map to patterns for this operation
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
        debug(options) {"Delete: #{solutions} against #{operands.to_sse}"}
        # Only binds the first solution
        solution = solutions.is_a?(RDF::Query::Solutions) ? solutions.first : solutions
        # Operands are an array of patterns and Queries (when named).
        # Create a new query made up all patterns
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
          debug(options) {"Delete pattern #{pattern.to_sse}"}
          queryable.delete(RDF::Statement.from(pattern)) if pattern.bound? || pattern.constant?
        end
        queryable
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        "DELETE {\n" +
          operands.first.to_sparql(delimiter: " .\n", **options) +
          "\n}"
      end
    end # Delete
  end # Operator
end; end # SPARQL::Algebra
