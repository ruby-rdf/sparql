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
      # @param [RDF::Query::Solutions] accumulator (RDF::Query::Solutions.new)
      #   For previous solutions to avoid duplicates.
      # @param [RDF::Literal::Integer] index (0)
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
        subject, object = options[:subject], options[:object]
        min, max, op = *operands
        debug(options) {"Path{#{min},#{max}}[#{index}] #{[subject, op, object].to_sxp}"}
        #require 'byebug'; byebug if index == RDF::Literal(2)

        # All subjects and objects
        solutions = if index.zero? && min.zero?
          PathZero.new(operand).execute(queryable, **options)
        else
          RDF::Query::Solutions.new
        end

        # This should only happen in the min == max == 0 use case.
        if index == max && max.zero?
          solutions.each(&block) if block_given? # Only at top-level
          return solutions
        end

        # Move to 1-based index
        if index.zero?
          index += 1
          debug(options) {"Path{#{min},#{max}}[#{index}] #{[subject, op, object].to_sxp}"}
        end

        # Solutions where predicate exists
        query = if op.is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [subject, op, object]
          end
        else
          op
        end

        # Recurse into query
        immediate_solutions = 
          query.execute(queryable, depth: options[:depth].to_i + 1, **options)

        # If there are no immediate solutions, return any zero-solutions (only when min==index==0)
        return solutions if immediate_solutions.empty?

        immediate_solutions += solutions

        recursive_solutions = RDF::Query::Solutions.new

        immediate_solutions.reject {|s| accumulator.include?(s)}.each do |solution|
          debug(options) {"(immediate solution)-> #{solution.to_sxp}"}

          # Recurse on subject, if is a variable
          case
          when subject.variable? && object.variable?
            # Query starting with bound object as subject, but replace result with subject
            rs = self.execute(queryable, **options.merge(
              subject: solution[object],
              accumulator: (accumulator + immediate_solutions),
              index: index + 1,
              depth: options[:depth].to_i + 1)).map {|s| s.merge(subject.to_sym => solution[subject])}
            # Query starting with bound subject as object, but replace result with subject
            ro = self.execute(queryable, **options.merge(
              object: solution[subject],
              accumulator: (accumulator + immediate_solutions),
              index: index + 1,
              depth: options[:depth].to_i + 1)).map {|s| s.merge(object.to_sym => solution[object])}
            recursive_solutions += (rs + ro).uniq
          when subject.variable?
            recursive_solutions += self.execute(queryable, **options.merge(
              object: solution[subject],
              accumulator: (accumulator + immediate_solutions),
              index: index + 1,
              depth: options[:depth].to_i + 1)).uniq
          when object.variable?
            recursive_solutions += self.execute(queryable, **options.merge(
              subject: solution[object],
              accumulator: (accumulator + immediate_solutions),
              index: index + 1,
              depth: options[:depth].to_i + 1)).uniq
          end
        end unless index == max
        debug(options) {"(recursive solutions)-> #{recursive_solutions.to_sxp}"}

        # If min > index and there are no recursive solutions, then there are no solutions.
        solutions = if min > index && recursive_solutions.empty?
          recursive_solutions
        else
          (immediate_solutions + recursive_solutions).uniq
        end
        debug(options) {"(solutions)-> #{solutions.to_sxp}"}

        solutions.each(&block) if block_given? # Only at top-level
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
