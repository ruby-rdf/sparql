module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `modify` operator.
    #
    # Wraps delete/insert
    #
    # If `options` contains any of the Protocol attributes, it is treated as if there is a USING or USING NAMED clause inserted.
    #
    # * `using-graph-uri`
    # * `using-named-graph-uri`
    #
    # [41]  Modify ::= ( 'WITH' iri )? ( DeleteClause InsertClause? | InsertClause ) UsingClause* 'WHERE' GroupGraphPattern
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
    # @see XXX
    class Modify < Operator
      include SPARQL::Algebra::Update

      NAME = [:modify]

      ##
      # Executes this upate on the given `writable` graph or repository.
      #
      # Execute the first operand to get solutions, and apply those solutions to the subsequent operators.
      #
      # If `options` contains any of the Protocol attributes, any `using` clause is removed and a new `using` clause is added with entries taken from the `using-graph-uri` and `using-named-graph-uri`.
      #
      # It is an error to supply the using-graph-uri or using-named-graph-uri parameters when using this protocol to convey a SPARQL 1.1 Update request that contains an operation that uses the USING, USING NAMED, or WITH clause.
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
        debug(options) {"Modify"}
        query = operands.shift

        if %i(using-graph-uri using-named-graph-uri).any? {|k| options.key?(k)}
          raise ArgumentError,
            "query contains USING/WITH clause, which is incompatible with using-graph-uri or using-named-graph-uri query parameters" if
            query.is_a?(Operator::Using) || query.is_a?(Operator::With)

          debug("=> Insert USING clause", options)
          defaults = Array(options.delete(:'using-graph-uri')).map {|uri| RDF::URI(uri)}
          named = Array(options.delete(:'using-named-graph-uri')).map {|uri| [:named, RDF::URI(uri)]}
          
          query = Operator::Using.new((defaults + named), query, **options)
        end

        queryable.query(query, **options.merge(depth: options[:depth].to_i + 1)) do |solution|
          debug(options) {"(solution)=>#{solution.inspect}"}

          # Execute each operand with queryable and solution
          operands.each do |op|
            op.execute(queryable, solutions: solution, **options.merge(depth: options[:depth].to_i + 1))
          end
        end
        queryable
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        if operands.first.is_a?(With)
          operands.first.to_sparql(**options)
        else
          # The content of the WHERE clause, may be USING
          content = operands.first.to_sparql(top_level: false, **options)

          # DELETE | INSERT | DELETE INSERT
          str = operands[1..-1].to_sparql(top_level: false, delimiter: "\n", **options) + "\n"

          # Append the WHERE or USING clause
          str << if operands.first.is_a?(Using)
            content
          else
            Operator.to_sparql(content, project: nil, **options)
          end
        end
      end
    end # Modify
  end # Operator
end; end # SPARQL::Algebra
