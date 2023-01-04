module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `with` operator.
    #
    # The WITH clause provides a convenience for when an operation primarily refers to a single graph.
    #
    # [41]  Modify ::= ( 'WITH' iri )? ( DeleteClause InsertClause? | InsertClause ) UsingClause* 'WHERE' GroupGraphPattern
    #
    # @example SPARQL Grammar
    #   PREFIX  :     <http://example/>
    #   WITH :g
    #   DELETE { <base:s> ?p ?o . }
    #   WHERE { ?s ?p ?o }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (update
    #     (modify
    #      (with :g
    #       (bgp (triple ?s ?p ?o))
    #       (delete ((triple <base:s> ?p ?o)))))))
    #
    # @see https://www.w3.org/TR/sparql11-update/#deleteInsert
    class With < Operator
      include SPARQL::Algebra::Update

      NAME = :with

      ##
      # Executes this upate on the given `writable` graph or repository.
      #
      # Effectively filters results by setting a default `__graph_name__` variable so that it is used when binding to perform update operations on the appropriate triples.
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
        debug(options) {"With: #{operand.to_sse}"}
        # Bound variable
        name = operands.shift

        unless queryable.has_graph?(name)
          debug(options) {"=> default data source #{name}"}
          load_opts = {logger: options.fetch(:logger, false), base_uri: name}
          debug(options) {"=> load #{name}"}
          queryable.load(name.to_s, **load_opts)
        end

        # Set name for RDF::Graph descendants having no graph_name to the name variable
        each_descendant do |op|
          case op
          when RDF::Query, RDF::Query::Pattern
            unless op.graph_name
              debug(options) {"set graph_name on #{op.to_sse}"}
              op.graph_name = RDF::Query::Variable.new(:__graph_name__, name)
            end
          end
        end
        query = operands.shift

        # Restrict query portion to this graph
        queryable.query(query, **options.merge(depth: options[:depth].to_i + 1)) do |solution|
          debug(options) {"(solution)=>#{solution.inspect}"}

          # Execute each operand with queryable and solution
          operands.each do |op|
            op.execute(queryable, solutions: solution, **options.merge(depth: options[:depth].to_i + 1))
          end
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        with, where, *ops = operands
        str = "WITH #{with.to_sparql(**options)}\n"

        # The content of the WHERE clause, may be USING
        content = where.to_sparql(top_level: false, **options)

        # DELETE | INSERT | DELETE INSERT
        str << ops.to_sparql(top_level: false, delimiter: "\n", **options) + "\n"

        # Append the WHERE or USING clause
        str << if where.is_a?(Using)
          content
        else
          Operator.to_sparql(content, project: nil, **options)
        end
      end
    end # With
  end # Operator
end; end # SPARQL::Algebra
