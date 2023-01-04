module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `prefix` operator.
    #
    # [6]   PrefixDecl              ::= 'PREFIX' PNAME_NS IRIREF
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example/>
    #   SELECT * { :s :p :o }
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (bgp (triple :s :p :o)))
    #
    # @see https://www.w3.org/TR/sparql11-query/#QSynIRI
    class Prefix < Binary
      include Query
      
      NAME = [:prefix]

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
        debug(options) {"Prefix"}
        @solutions = queryable.query(operands.last, **options.merge(depth: options[:depth].to_i + 1), &block)
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

      # Combine two prefix definitions, merging their definitions
      # @param [Prefix] other
      # @return [Prefix] self
      def merge!(other)
        operands[0] += other.operands[0]
        self
      end

      # Query results in a boolean result (e.g., ASK)
      # @return [Boolean]
      def query_yields_boolean?
        operands.last.query_yields_boolean?
      end

      # Query results statements (e.g., CONSTRUCT, DESCRIBE, CREATE)
      # @return [Boolean]
      def query_yields_statements?
        operands.last.query_yields_statements?
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        prefixes = {}
        str = operands.first.map do |(pfx, sfx)|
          pfx = pfx.to_s.chomp(':').to_sym
          prefixes[pfx] = sfx
          "PREFIX #{pfx}: #{sfx.to_sparql}\n"
        end.join("")

        str << operands.last.to_sparql(prefixes: prefixes, **options)
      end
    end # Prefix
  end # Operator
end; end # SPARQL::Algebra
