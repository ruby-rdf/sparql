module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `sequence` operator.
    #
    # Sequences through each operand
    #
    # @example
    #   (sequence
    #     (bgp
    #       (triple ?s ?p ??0)
    #       (triple ??0 rdf:first ??1)
    #       (triple ??0 rdf:rest ??2)
    #       (triple ??2 rdf:first ??3)
    #       (triple ??2 rdf:rest rdf:nil))
    #     (path ??1 (seq (path* :p) :q) 123)
    #     (path ??3 (reverse :r) "hello"))
    #
    # @see XXX
    class Sequence < Operator
      include SPARQL::Algebra::Update

      NAME = :sequence

      ##
      # Executes this upate on the given `writable` graph or repository.
      #
      # XXX
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
        debug(options) {"Sequence"}
        queryable
      end
    end # Sequence
  end # Operator
end; end # SPARQL::Algebra
