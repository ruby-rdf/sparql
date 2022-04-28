module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path?` (ZeroOrOnePath) operator.
    #
    # [91]  PathElt ::= PathPrimary PathMod?
    # [93]  PathMod ::= '*' | '?' | '+' | '{' INTEGER? (',' INTEGER?)? '}'
    
    # @example SPARQL Grammar
    #   PREFIX : <http://example/> 
    #   SELECT * WHERE {
    #     :a (:p/:p)? ?t
    #   } 
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (path :a (path? (seq :p :p)) ?t))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_evalPP_ZeroOrOnePath
    class PathOpt < Operator::Unary
      include Query
      
      NAME = :path?

      ##
      # Optional path:
      #
      #    (path x (path? :p) y)
      #     => (union (bgp ((x :p y))) (filter (x = y) (solution x y)))
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
        debug(options) {"Path? #{[subject, operands, object].to_sse}"}

        query = PathZero.new(operand)
        solutions = query.execute(queryable, **options.merge(depth: options[:depth].to_i + 1))

        # Solutions where predicate exists
        query = if operand.is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [subject, operand, object]
          end
        else # path
          operand
        end

        # Recurse into query
        solutions += query.execute(queryable, **options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"(path?)=> #{solutions.to_sxp}"}
        solutions.each(&block) if block_given?
        solutions
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(#{operands.first.to_sparql(**options)})?"
      end
    end # PathOpt
  end # Operator
end; end # SPARQL::Algebra
