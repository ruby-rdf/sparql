module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `pathRange` (CountingPath) operator.
    #
    # [91]  PathElt ::= PathPrimary PathMod?
    # [93]  PathMod ::= '*' | '?' | '+' | '{' INTEGER? (',' INTEGER?)? '}'
    #
    # @example SPARQL Grammar range with fixed length
    #   PREFIX : <http://example/> 
    #   SELECT * WHERE {
    #     :a :p{2} ?z
    #   } 
    #
    # @example SSE range with fixed length only
    #   (prefix ((: <http://example/>))
    #    (path :a (pathRange 2 2 :p) ?z))
    #
    # @example SPARQL Grammar range with min only
    #   PREFIX : <http://example/> 
    #   SELECT * WHERE {
    #     :a :p{1,} ?z
    #   } 
    #
    # @example SSE range with min only
    #   (prefix ((: <http://example/>))
    #    (path :a (pathRange 1 * :p) ?z))
    #
    # @example SPARQL Grammar range with max only
    #   PREFIX : <http://example/> 
    #   SELECT * WHERE {
    #     :a :p{,2} ?z
    #   } 
    #
    # @example SSE range with max only
    #   (prefix ((: <http://example/>))
    #    (path :a (pathRange 0 2 :p) ?z))
    #
    # @example SPARQL Grammar range with min and max
    #   PREFIX : <http://example/> 
    #   SELECT * WHERE {
    #     :a :p{1,2} ?z
    #   } 
    #
    # @example SSE range with min and max
    #   (prefix ((: <http://example/>))
    #    (path :a (pathRange 1 2 :p) ?z))
    #
    class PathRange < Operator::Ternary
      include Query
      
      NAME = :"pathRange"

      ##
       # Initializes a new operator instance.
       #
       # @param  [RDF::Literal::Integer] max
       #   the range minimum
       # @param  [RDF::Literal::Integer, Symbol] min
       #   the range maximum (may be `*`)
       # @param  [SPARQL::Operator] path
       #   the query
       # @param  [Hash{Symbol => Object}] options
       #   any additional options (see {Operator#initialize})
       # @raise  [TypeError] if any operand is invalid
       # @raise  [ArgumentError] range element is invalid
      def initialize(min, max, path, **options)
        raise ArgumentError, "expect min <= max {#{min},#{max}}" if
          max.is_a?(RDF::Literal::Integer) && max < min
        super
      end

      ##
      # Path with lower and upper bounds on lenghts:
      #
      #    (path :a (pathRange 1 2 :p) :b)
      #    => (path)
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
        min, max, opers = *operands
        debug(options) {"Path{#{min},#{max}} #{[subject, opers, object].to_sse}"}

        # FIXME
        query = PathOpt.new(PathPlus.new(*opers))
        query.execute(queryable, depth: options[:depth].to_i + 1, **options, &block)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        min, max, path = operands
        "(#{path.to_sparql(**options)})" +
        if max == :*
          "{#{min},}"
        elsif min == max
          "{#{min}}"
        else
          "{#{min},#{max}}"
        end
      end
    end # PathStar
  end # Operator
end; end # SPARQL::Algebra
