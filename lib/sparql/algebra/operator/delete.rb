module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `delete` operator.
    #
    # The DELETE operation is a form of the DELETE/INSERT operation having no INSERT section
    #
    # @example
    #   (delete ((triple ?s ?p ?o))))
    #
    # @see http://www.w3.org/TR/sparql11-update/#delete
    class Delete < Operator::Unary
      include SPARQL::Algebra::Update

      NAME = [:delete]

      ##
      # Executes this upate on the given `writable` graph or repository.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to write
      # @param  [RDF::Query::Solution] solution
      #   Solution to map to patterns for this operation
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @option options [Boolean] debug
      #   Query execution debugging
      # @return [RDF::Queryable]
      #   Returns queryable.
      # @raise [IOError]
      #   If `from` does not exist, unless the `silent` operator is present
      # @see    http://www.w3.org/TR/sparql11-update/
      def execute(queryable, solution, options = {})
        debug(options) {"Delete: #{solution} against #{operands.to_sse}"}
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
          debug(options) {"Delete statement #{statement.to_sse}"}
          queryable.delete(RDF::Statement.from(pattern)) if pattern.bound? || pattern.constant?
        end
        queryable
      end
    end # Delete
  end # Operator
end; end # SPARQL::Algebra
