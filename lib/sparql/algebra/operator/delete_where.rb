module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `deleteWhere` operator.
    #
    # The DELETE WHERE operation is a shortcut form for the DELETE/INSERT operation where bindings matched by the WHERE clause are used to define the triples in a graph that will be deleted.
    #
    # [40]  DeleteWhere             ::= 'DELETE WHERE' QuadPattern
    #
    # @example SPARQL Grammar
    #   PREFIX     : <http://example.org/> 
    #   PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
    #   DELETE WHERE { :a foaf:knows ?b }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>)
    #     (foaf: <http://xmlns.com/foaf/0.1/>))
    #    (update
    #     (deleteWhere ((triple :a foaf:knows ?b)))))
    #
    # @see https://www.w3.org/TR/sparql11-update/#deleteWhere
    class DeleteWhere < Operator::Unary
      include SPARQL::Algebra::Update

      NAME = [:deleteWhere]

      ##
      # Query the operand, and delete all statements created by binding each solution to the patterns
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to write
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @option options [Boolean] debug
      #   Query execution debugging
      # @return [RDF::Queryable]
      #   Returns queryable.
      # @raise [IOError]
      #   If `from` does not exist, unless the `silent` operator is present
      # @see    https://www.w3.org/TR/sparql11-update/
      def execute(queryable, **options)
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
        query = RDF::Query.new(*patterns, **{}) # FIXME: added hash argument needed until Statement#to_hash removed.
        debug(options) {"DeleteWhere query #{query.to_sse}"}
        query.execute(queryable, **options.merge(depth: options[:depth].to_i + 1)) do |solution|
          debug(options) {"DeleteWhere solution #{solution.to_sse}"}
          query.each_statement do |pattern|
            pattern = pattern.dup.bind(solution)
            debug(options) {"DeleteWhere pattern #{pattern.to_sse}"}
            queryable.delete(RDF::Statement.from(pattern)) if pattern.bound? || pattern.constant?
          end
        end
        queryable
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        "DELETE WHERE {\n" +
          operands.first.to_sparql(top_level: false, delimiter: ". \n", **options) +
          "\n}"
      end
    end # DeleteWhere
  end # Operator
end; end # SPARQL::Algebra
