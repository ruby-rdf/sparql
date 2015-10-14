module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `create` operator.
    #
    # This operation creates a graph in the Graph Store
    #
    # This is a no-op for RDF.rb implementations, unless the graph exists
    #
    # @example
    #   (create silent <graph>)
    #
    # @see http://www.w3.org/TR/sparql11-update/#create
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
      # @see    http://www.w3.org/TR/sparql11-update/
      def execute(queryable, options = {})
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
    end # Create
  end # Operator
end; end # SPARQL::Algebra
