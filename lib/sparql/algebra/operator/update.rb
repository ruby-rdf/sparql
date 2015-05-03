module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `prefix` operator.
    #
    # @example
    #   (update
    #     (modify
    #       (bgp (triple ?s ?p ?o))
    #       (insert ((triple ?s ?p "q")))))
    #
    # @see http://www.w3.org/TR/sparql11-update/#graphUpdate
    class Update < Operator
      include SPARQL::Algebra::Update
      
      NAME = [:update]

      ##
      # Executes this upate on the given `queryable` graph or repository.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to write
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @option options [Boolean] debug
      #   Query execution debugging
      # @return [RDF::Queryable]
      #   Returns the dataset.
      # @raise [NotImplementedError]
      #   If an attempt is made to perform an unsupported operation
      # @raise [IOError]
      #   If `queryable` is immutable
      # @see    http://www.w3.org/TR/sparql11-update/
      def execute(queryable, options = {})
        debug(options) {"Update"}
        raise IOError, "queryable is not mutable" unless queryable.mutable?
        operands.each do |op|
          op.execute(queryable, options.merge(depth: options[:depth].to_i + 1))
        end
        queryable
      end
    end # Update
  end # Operator
end; end # SPARQL::Algebra
