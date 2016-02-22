module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path*` (ZeroOrMorePath) operator.
    #
    # @example
    #   (path* :p)
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_evalPP_ZeroOrMorePath
    class PathStar < Operator::Unary
      include Query
      
      NAME = :"path*"

      ##
      # Path including zero length:
      #
      #    (path :a (path* :p) :b)
      #    => (path :a (path? (path+ :p)) :b)
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
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, options = {}, &block)
        subject, object = options[:subject], options[:object]
        debug(options) {"Path* #{[subject, operands, object].to_sse}"}

        # (:x :p* :y) => (:x (:p+)? :y)
        query = PathOpt.new(PathPlus.new(*operands))
        query.execute(queryable, options.merge(depth: options[:depth].to_i + 1), &block)
      end
    end # PathStar
  end # Operator
end; end # SPARQL::Algebra
