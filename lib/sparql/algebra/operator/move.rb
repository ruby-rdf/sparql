module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `move` operator.
    #
    # The MOVE operation is a shortcut for moving all data from an input graph into a destination graph. The input graph is removed after insertion and data from the destination graph, if any, is removed before insertion.
    #
    # @example
    #   (move silent <iri> to default)
    #
    # @see http://www.w3.org/TR/sparql11-update/#move
    class Move < Operator
      include SPARQL::Algebra::Update

      NAME = [:move]

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
        debug(options) {"Move"}
        silent = operands.first == :silent
        operands.shift if silent

        src_name, dest_name = operands[-2..-1]
        raise ArgumentError, "move expected two operands, got #{operands.length}" unless operands.length == 2
        raise ArgumentError, "move from must be IRI or :default" unless src_name == :default || src_name.is_a?(RDF::URI)
        raise ArgumentError, "move to must be IRI or :default" unless dest_name == :default || dest_name.is_a?(RDF::URI)
        src = queryable.enum_graph.detect {|g| g.to_s == src_name.to_s}

        if src.nil?
          raise IOError, "move operation source does not exist" unless silent
        elsif dest_name == src_name
          # No operation
        else
          dest = queryable.enum_graph.detect {|g| g.to_s == dest_name.to_s}
          
          # Clear destination first
          dest.clear! if dest

          # Copy statements using destination graph
          src.each do |statement|
            statement = statement.dup
            statement.graph_name = (dest_name unless dest_name == :default)
            queryable << statement
          end

          # Clear source
          src.clear!
        end
        queryable
      end
    end # Move
  end # Operator
end; end # SPARQL::Algebra
