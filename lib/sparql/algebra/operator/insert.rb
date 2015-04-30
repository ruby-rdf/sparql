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
        debug(options) {"Insert"}
        queryable
      end
    end # Insert
  end # Operator
end; end # SPARQL::Algebra
