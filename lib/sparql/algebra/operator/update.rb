module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `prefix` operator.
    #
    # [29]  Update                  ::= Prologue ( Update1 ( ';' Update )? )?
    #
    # @example SPARQL Grammar
    #   PREFIX     : <http://example.org/> 
    #   PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
    #   DELETE  { ?a foaf:knows ?b }
    #   INSERT { ?b foaf:knows ?a }
    #   WHERE { ?a foaf:knows ?b }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>)
    #            (foaf: <http://xmlns.com/foaf/0.1/>))
    #    (update
    #     (modify
    #      (bgp (triple ?a foaf:knows ?b))
    #      (delete ((triple ?a foaf:knows ?b)))
    #      (insert ((triple ?b foaf:knows ?a)))) ))
    #
    # @example SPARQL Grammar (update multiple)
    #   PREFIX     : <http://example.org/> 
    #   PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
    #   
    #   DELETE { ?a foaf:knows ?b . }
    #   WHERE { ?a foaf:knows ?b . }
    #   ;
    #   INSERT { ?b foaf:knows ?a . }
    #   WHERE { ?a foaf:knows ?b .}
    #
    # @example SSE (update multiple)
    #   (prefix ((: <http://example.org/>)
    #            (foaf: <http://xmlns.com/foaf/0.1/>))
    #    (update
    #     (modify
    #      (bgp (triple ?a foaf:knows ?b))
    #      (delete ((triple ?a foaf:knows ?b))))
    #     (modify
    #      (bgp (triple ?a foaf:knows ?b))
    #      (insert ((triple ?b foaf:knows ?a))))))
    #
    # @see https://www.w3.org/TR/sparql11-update/#graphUpdate
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
      # @see    https://www.w3.org/TR/sparql11-update/
      def execute(queryable, **options)
        debug(options) {"Update"}
        raise IOError, "queryable is not mutable" unless queryable.mutable?
        operands.each do |op|
          op.execute(queryable, **options.merge(depth: options[:depth].to_i + 1))
        end
        queryable
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        str = operands.map { |e| e.to_sparql(**options) }.join(";\n")
      end
    end # Update
  end # Operator
end; end # SPARQL::Algebra
