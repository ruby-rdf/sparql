module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Service operator.
    #
    # [59]  ServiceGraphPattern ::= 'SERVICE' 'SILENT'? VarOrIri GroupGraphPattern
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/> 
    #   
    #   SELECT ?s ?o1 ?o2  {
    #     ?s ?p1 ?o1 .
    #     SERVICE <http://example.org/sparql> {
    #       ?s ?p2 ?o2
    #     }
    #   } 
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>))
    #     (project (?s ?o1 ?o2)
    #       (join
    #         (bgp (triple ?s ?p1 ?o1))
    #         (service :sparql
    #           (bgp (triple ?s ?p2 ?o2))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#QSynIRI
    class Service < Operator
      include Query
  
      NAME = [:service]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Really a pass-through, as this is a syntactic object used for providing
      # graph_name for URIs.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @yield  [solution]
      #   each matching solution, statement or boolean
      # @yieldparam  [RDF::Statement, RDF::Query::Solution, Boolean] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)
        debug(options) {"Service"}
        silent = operands.first == :silent
        location, query = operands
        query_sparql = query.to_sparql
        debug(options) {"query: #{query_sparql}"}
        raise NotImplementedError, "SERVICE operator not implemented"
      end

      ##
      # Returns an optimized version of this query.
      #
      # Replace with the query with URIs having their lexical shortcut removed
      #
      # @return [Prefix] a copy of `self`
      # @see SPARQL::Algebra::Expression#optimize
      def optimize(**options)
        operands.last.optimize(**options)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        silent = operands.first == :silent
        ops = silent ? operands[1..-1] : operands
        location, query = ops

        
        str = "SERVICE "
        str << "SILENT " if silent
        str << location.to_sparql(**options) + " {" + query.to_sparql(**options) + "}"
        str
      end
    end # Service
  end # Operator
end; end # SPARQL::Algebra
