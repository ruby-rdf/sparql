module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `drop` operator.
    #
    # The DROP operation removes the specified graph(s) from the Graph Store
    #
    # Equivalent to `clear` in this implementation
    #
    # [33]  Drop                    ::= 'DROP' 'SILENT'? GraphRefAll
    #
    # @example SPARQL Grammar (SILENT DEFAULT)
    #   DROP SILENT DEFAULT
    #
    # @example SSE (SILENT DEFAULT)
    #   (update
    #    (drop silent default))
    #
    # @example SPARQL Grammar (IRI)
    #   DROP GRAPH <http://example.com/>
    #
    # @example SSE (IRI)
    #   (update (drop <http://example.com/>))
    #
    # @see https://www.w3.org/TR/sparql11-update/#drop
    class Drop < Operator
      include SPARQL::Algebra::Update

      NAME = [:drop]

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
        debug(options) {"Drop"}
        silent = operands.first == :silent
        operands.shift if silent

        raise ArgumentError, "drop expected operand to be 'default', 'named', 'all', or an IRI" unless operands.length == 1
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
            raise IOError, "drop operation graph does not exist" unless silent
          end
        else
          raise ArgumentError, "drop expected operand to be 'default', 'named', 'all', or an IRI" 
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
        str = "DROP "
        str << "SILENT " if operands.first == :silent
        str << "GRAPH " if operands.last.is_a?(RDF::URI)
        str << operands.last.to_sparql(**options)
      end
    end # Drop
  end # Operator
end; end # SPARQL::Algebra
