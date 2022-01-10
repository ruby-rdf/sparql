module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `create` operator.
    #
    # This operation creates a graph in the Graph Store
    #
    # This is a no-op for RDF.rb implementations, unless the graph exists
    #
    # [34]  Create                  ::= 'CREATE' 'SILENT'? GraphRef
    #
    # @example SPARQL Grammar
    #   CREATE SILENT GRAPH <http://example.org/g1>
    #
    # @example SSE
    #   (update (create silent <http://example.org/g1>))
    #
    # @see https://www.w3.org/TR/sparql11-update/#create
    class Create < Operator
      include SPARQL::Algebra::Update

      NAME = [:create]

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
        debug(options) {"Create"}
        silent = operands.first == :silent
        operands.shift if silent

        iri = operands.first
        raise ArgumentError, "clear expected a single IRI" if operands.length != 1 || !iri.is_a?(RDF::URI)
        if queryable.has_graph?(iri)
          raise IOError, "create operation graph #{iri.to_ntriples} exists" unless silent
        end
        queryable
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        silent = operands.first == :silent
        str = "CREATE "
        str << "SILENT " if operands.first == :silent
        str << "GRAPH " if operands.last.is_a?(RDF::URI)
        str << operands.last.to_sparql(**options)
      end
    end # Create
  end # Operator
end; end # SPARQL::Algebra
