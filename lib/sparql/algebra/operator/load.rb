module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `load` operator.
    #
    # The LOAD operation reads an RDF document from a IRI and inserts its triples into the specified graph in the Graph Store. The specified destination graph should be created if required; again, implementations providing an update service over a fixed set of graphs must return with failure for a request that would create a disallowed graph. If the destination graph already exists, then no data in that graph will be removed.
    #
    # @example
    #   (load <remote> <g>)
    #
    # @see http://www.w3.org/TR/sparql11-update/#load
    class Load < Operator
      include SPARQL::Algebra::Update

      NAME = [:load]

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
        debug(options) {"Load"}
        silent = operands.first == :silent
        operands.shift if silent

        raise ArgumentError, "load expected one or two operands, got #{operands.length}" unless [1,2].include?(operands.length)

        location, name = operands
        queryable.load(location, graph_name: name)
      rescue IOError, Errno::ENOENT
        raise unless silent
      ensure
        queryable
      end
    end # Load
  end # Operator
end; end # SPARQL::Algebra
