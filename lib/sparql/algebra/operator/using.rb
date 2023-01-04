module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `using` operator.
    #
    # The USING and USING NAMED clauses affect the RDF Dataset used while evaluating the WHERE clause. This describes a dataset in the same way as FROM and FROM NAMED clauses describe RDF Datasets in the SPARQL 1.1 Query Language
    #
    # [44]  UsingClause             ::= 'USING' ( iri | 'NAMED' iri )
    #
    # @example SPARQL Grammar
    #   PREFIX     : <http://example.org/> 
    #   PREFIX foaf: <http://xmlns.com/foaf/0.1/> 
    #   
    #   DELETE { ?s ?p ?o }
    #   USING <http://example.org/g2>
    #   WHERE {
    #     :a foaf:knows ?s .
    #     ?s ?p ?o 
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>) (foaf: <http://xmlns.com/foaf/0.1/>))
    #    (update
    #     (modify
    #      (using (:g2)
    #       (bgp (triple :a foaf:knows ?s) (triple ?s ?p ?o)))
    #      (delete ((triple ?s ?p ?o)))) ))
    #
    # @example SPARQL Grammar (multiple clauses)
    #   PREFIX     : <http://example.org/> 
    #   
    #   INSERT { ?s ?p "q" }
    #   USING :g1
    #   USING :g2
    #   WHERE { ?s ?p ?o }
    #
    # @example SSE (multiple clauses)
    #   (prefix ((: <http://example.org/>))
    #    (update
    #     (modify
    #      (using (:g1 :g2) (bgp (triple ?s ?p ?o)))
    #      (insert ((triple ?s ?p "q"))))))
    #
    # @see https://www.w3.org/TR/sparql11-update/#add
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
      # @see    https://www.w3.org/TR/sparql11-update/
      def execute(queryable, **options, &block)
        debug(options) {"Using"}
        Dataset.new(*operands).execute(queryable, **options.merge(depth: options[:depth].to_i + 1), &block)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        str = "\n" + operands.first.map do |op|
          "USING #{op.to_sparql(**options)}\n"
        end.join("")
        content = operands.last.to_sparql(top_level: false, **options)
        str << Operator.to_sparql(content, project: nil, **options)
      end
    end # Using
  end # Operator
end; end # SPARQL::Algebra
