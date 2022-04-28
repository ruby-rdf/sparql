module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `deleteData` operator.
    #
    # The DELETE DATA operation removes some triples, given inline in the request, if the respective graphs in the Graph Store contain those
    #
    # [39]  DeleteData              ::= 'DELETE DATA' QuadData
    #
    # @example SPARQL Grammar
    #   PREFIX     : <http://example.org/> 
    #   PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
    #   DELETE DATA {
    #     :a foaf:knows :b .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>) (foaf: <http://xmlns.com/foaf/0.1/>))
    #    (update (deleteData ((triple :a foaf:knows :b)))))
    #
    # @see https://www.w3.org/TR/sparql11-update/#deleteData
    class DeleteData < Operator::Unary
      include SPARQL::Algebra::Update

      NAME = [:deleteData]

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
          debug(options) {"DeleteData #{op.to_sxp}"}
          queryable.delete(op)
        end
        queryable
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        "DELETE DATA {\n" +
          operands.first.to_sparql(top_level: false, delimiter: ". \n", **options) +
          "\n}"
      end
    end # DeleteData
  end # Operator
end; end # SPARQL::Algebra
