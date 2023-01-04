module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path*` (ZeroOrMorePath) operator.
    #
    # [91]  PathElt ::= PathPrimary PathMod?
    # [93]  PathMod ::= '*' | '?' | '+' | '{' INTEGER? (',' INTEGER?)? '}'
    
    # @example SPARQL Grammar
    #   PREFIX : <http://example/> 
    #   SELECT * WHERE {
    #     :a :p* ?z
    #   } 
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (path :a (path* :p) ?z))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_evalPP_ZeroOrMorePath
    class PathStar < Operator::Unary
      include Query
      
      NAME = :"path*"

      ##
      # Path including at zero length:
      #
      #    (path :a (path* :p) :b)
      #
      # into
      #
      #    (path :a (path? (path+ :p)) :b)
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @option options [RDF::Term, RDF::Variable] :subject
      # @option options [RDF::Term, RDF::Variable] :object
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)
        subject, object = options[:subject], options[:object]
        debug(options) {"Path* #{[subject, operands, object].to_sse}"}

        # (:x :p* :y) => (:x (:p+)? :y)
        query = PathOpt.new(PathPlus.new(*operands))
        query.execute(queryable, **options.merge(depth: options[:depth].to_i + 1), &block)
      end
      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(#{operands.first.to_sparql(**options)})*"
      end
    end # PathStar
  end # Operator
end; end # SPARQL::Algebra
