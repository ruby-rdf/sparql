module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `insertData` operator.
    #
    # The INSERT DATA operation adds some triples, given inline in the request, into the Graph Store
    #
    # [38]  InsertData              ::= 'INSERT DATA' QuadData
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/ns#>
    #   INSERT DATA { GRAPH <http://example.org/g1> { :s :p :o } }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/ns#>))
    #    (update
    #     (insertData (
    #      (graph <http://example.org/g1> ((triple :s :p :o)))))))
    #
    # @see https://www.w3.org/TR/sparql11-update/#insertData
    class InsertData < Operator::Unary
      include SPARQL::Algebra::Update

      NAME = [:insertData]

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
      # @see    https://www.w3.org/TR/sparql11-update/
      def execute(queryable, **options)
        operand.each do |op|
          debug(options) {"InsertData #{op.to_sxp}"}
          queryable.insert(op)
        end
        queryable
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        "INSERT DATA {\n" +
          operands.first.to_sparql(top_level: false, delimiter: ". \n", **options) +
          "\n}"
      end
    end # InsertData
  end # Operator
end; end # SPARQL::Algebra
