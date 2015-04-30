module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `deleteWhere` operator.
    #
    # The DELETE WHERE operation is a shortcut form for the DELETE/INSERT operation where bindings matched by the WHERE clause are used to define the triples in a graph that will be deleted.
    #
    # @example
    #   (deleteWhere ((triple :a foaf:knows ?b))
    #
    # @see http://www.w3.org/TR/sparql11-update/#deleteWhere
    class DeleteWhere < Operator::Unary
      include SPARQL::Algebra::Update

      NAME = [:deleteWhere]

      ##
      # Executes this upate on the given `writable` graph or repository.
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
      # @see    http://www.w3.org/TR/sparql11-update/
      def execute(queryable, options = {})
        debug(options) {"DeleteWhere"}
        queryable
      end
    end # DeleteWhere
  end # Operator
end; end # SPARQL::Algebra
