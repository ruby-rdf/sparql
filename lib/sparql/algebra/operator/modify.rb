module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `modify` operator.
    #
    # Wraps delete/insert
    #
    # @example
    #   (modify
    #     (bgp (triple ?a foaf:knows ?b))
    #     (delete ((triple ?a foaf:knows ?b)))
    #     (insert ((triple ?b foaf:knows ?a)))
    #
    # @see XXX
    class Modify < Operator
      include SPARQL::Algebra::Update

      NAME = [:modify]

      ##
      # Executes this upate on the given `writable` graph or repository.
      #
      # Execute the first operand to get solutions, and apply those solutions to the subsequent operators.
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
        debug(options) {"Modify"}
        query = operands.shift

        queryable.query(query, options.merge(depth: options[:depth].to_i + 1)) do |solution|
          debug(options) {"(solution)=>#{solution.inspect}"}

          # Execute each operand with queryable and solution
          operands.each do |op|
            op.execute(queryable, solution, options.merge(depth: options[:depth].to_i + 1))
          end
        end
        queryable
      end
    end # Modify
  end # Operator
end; end # SPARQL::Algebra
