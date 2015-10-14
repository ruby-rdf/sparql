module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `add` operator.
    #
    # The ADD operation is a shortcut for inserting all data from an input graph into a destination graph. Data from the input graph is not affected, and initial data from the destination graph, if any, is kept intact.
    #
    # @example
    #   (add default <a>)
    #
    # @see http://www.w3.org/TR/sparql11-update/#add
    class Add < Operator
      include SPARQL::Algebra::Update

      NAME = [:add]

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
        debug(options) {"Add"}
        silent = operands.first == :silent
        operands.shift if silent

        src_name, dest_name = operands[-2..-1]
        raise ArgumentError, "add expected two operands, got #{operands.length}" unless operands.length == 2
        raise ArgumentError, "add from must be IRI or :default" unless src_name == :default || src_name.is_a?(RDF::URI)
        raise ArgumentError, "add to must be IRI or :default" unless dest_name == :default || dest_name.is_a?(RDF::URI)
        src = queryable.enum_graph.detect {|g| g.to_s == src_name.to_s}

        if src.nil?
          raise IOError, "add operation source does not exist" unless silent
        else
          src.each do |statement|
            statement = statement.dup
            statement.graph_name = (dest_name unless dest_name == :default)
            queryable << statement
          end
        end
        queryable
      end
    end # Add
  end # Operator
end; end # SPARQL::Algebra
