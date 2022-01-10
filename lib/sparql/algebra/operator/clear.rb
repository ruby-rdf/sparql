module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `clear` operator.
    #
    # The CLEAR operation removes all the triples in the specified graph(s) in the Graph Store.
    #
    # [32]  Clear                   ::= 'CLEAR' 'SILENT'? GraphRefAll
    #
    # @example SPARQL Grammar (SILENT DEFAULT)
    #   CLEAR SILENT DEFAULT
    #
    # @example SSE (SILENT DEFAULT)
    #   (update (clear silent default))
    #
    # @example SPARQL Grammar (IRI)
    #   CLEAR GRAPH <http://example.com/>
    #
    # @example SSE (IRI)
    #   (update (clear <http://example.com/>))
    #
    # @see https://www.w3.org/TR/sparql11-update/#clear
    class Clear < Operator
      include SPARQL::Algebra::Update

      NAME = [:clear]

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
        debug(options) {"Clear"}
        silent = operands.first == :silent
        operands.shift if silent

        raise ArgumentError, "clear expected operand to be 'default', 'named', 'all', or an IRI" unless operands.length == 1
        case operands.last
        when :default
          queryable.each_graph do |g|
            g.clear! unless g.graph_name
          end
        when :named
          queryable.each_graph do |g|
            g.clear! if g.graph_name
          end
        when :all
          queryable.clear!
        when RDF::URI
          if g = queryable.each_graph.detect {|c| c.graph_name == operands.last}
            g.clear!
          else
            raise IOError, "clear operation graph does not exist" unless silent
          end
        else
          raise ArgumentError, "clear expected operand to be 'default', 'named', 'all', or an IRI" 
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
        str = "CLEAR "
        str << "SILENT " if operands.first == :silent
        str << "GRAPH " if operands.last.is_a?(RDF::URI)
        str << operands.last.to_sparql(**options)
      end
    end # Clear
  end # Operator
end; end # SPARQL::Algebra
