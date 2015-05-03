module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `insertData` operator.
    #
    # The INSERT operation is a form of the DELETE/INSERT operation having no DELETE section
    #
    # @example
    #   (insert ((triple ?s ?p "q")))
    #
    # @see http://www.w3.org/TR/sparql11-update/#insert
    class Insert < Operator::Unary
      include SPARQL::Algebra::Update

      NAME = [:insert]

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
          debug(options) {"Insert statement #{statement.to_sse}"}
          # Only insert bound or constant patterns
          queryable.insert(RDF::Statement.from(pattern)) if pattern.bound? || pattern.constant?
        end
        queryable
      end
    end # Insert
  end # Operator
end; end # SPARQL::Algebra
