module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `pathRange` (NonCountingPath) operator.
    #
    # Property path ranges allow specific path lenghts to be queried. The minimum range describes the minimum path length that will yield solutions, and the maximum range the maximum path that will be returned. A minumum of zero is similar to the `path?` operator. The maximum range of `*` is similar to the `path*` or `path+` operators.
    #
    # For example, the two queries are functionally equivalent:
    #
    #     SELECT * WHERE {:a :p{1,2} :b}
    #
    #     SELECT * WHERE {:a (:p/:p?) :b}
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
      # @param [RDF::Query::Solutions] accumulator (RDF::Query::Solutions.new)
      #   For previous solutions to avoid duplicates.
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @option options [RDF::Term, RDF::Variable] :subject
      # @option options [RDF::Term, RDF::Variable] :object
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable,
                  accumulator: RDF::Query::Solutions.new,
                  index: RDF::Literal(0),
                  **options,
                  &block)

        min, max, op = *operands
        subject, object = options[:subject], options[:object]
        debug(options) {"Path{#{min},#{max}} #{[subject, op, object].to_sse}"}

        path_mm = if min.zero? && max.is_a?(RDF::Literal::Integer) && max.zero?
          PathZero.new(op, **options)
        else
          # Build up a sequence
          path_opt = nil
          seq_len = min.to_i
          if max.is_a?(RDF::Literal::Integer)
            # min to max is a sequence of optional sequences
            opt_len = (max - min).to_i
            while opt_len > 0 do
              path_opt = PathOpt.new(path_opt ? Seq.new(op, path_opt, **options) : op, **options)
              opt_len -= 1
            end
          elsif seq_len > 0
            path_opt = PathPlus.new(op, **options)
            seq_len -= 1
          else
            path_opt = PathStar.new(op, **options)
          end

          # sequence ending in op, op+, op*, or path_opt
          path_seq = nil
          while seq_len > 0 do
            path_seq = if path_opt
              opt, path_opt = path_opt, nil
              Seq.new(op, opt, **options)
            elsif path_seq
              Seq.new(op, path_seq, **options)
            else
              op
            end
            seq_len -= 1
          end
          path_seq || path_opt || op
        end
        debug(options) {"=> #{path_mm.to_sse}"}

        # After this, path_mm may just be the original op, which can be a term, not an operator.
        if path_mm.is_a?(RDF::Term)
          path_mm = RDF::Query.new do |q|
            q.pattern [subject, path_mm, object]
          end
        end

        solutions = path_mm.execute(queryable, **options.merge(depth: options[:depth].to_i + 1)).uniq
        debug(options) {"(path{#{min},#{max}})=> #{solutions.to_sxp}"}
        solutions.each(&block) if block_given?
        solutions
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
