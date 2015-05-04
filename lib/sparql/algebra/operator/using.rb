module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `using` operator.
    #
    # The USING and USING NAMED clauses affect the RDF Dataset used while evaluating the WHERE clause. This describes a dataset in the same way as FROM and FROM NAMED clauses describe RDF Datasets in the SPARQL 1.1 Query Language
    #
    # @example
    #   (using (:g1) (bgp (triple ?s ?p ?o)))
    #
    # @see http://www.w3.org/TR/sparql11-update/#add
    class Using < Operator
      include SPARQL::Algebra::Query

      NAME = :using

      ##
      # Executes this upate on the given `writable` graph or repository.
      #
      # Delegates to Dataset
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
      def execute(queryable, options = {}, &block)
        debug(options) {"Using"}
        Dataset.new(*operands).execute(queryable, options.merge(depth: options[:depth].to_i + 1), &block)
      end
    end # Using
  end # Operator
end; end # SPARQL::Algebra
