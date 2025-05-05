module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path` operator.
    #
    # The second element represents a set of predicates which ar associated with the first (subject) and last (object) operands.
    #
    # [88]  Path ::= PathAlternative
    #
    # @example SPARQL Grammar
    #   PREFIX :  <http://www.example.org/>
    #   SELECT ?t
    #   WHERE {
    #     :a :p1|:p2/:p3|:p4 ?t
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://www.example.org/>))
    #    (project (?t)
    #     (path :a
    #      (alt
    #       (alt :p1 (seq :p2 :p3))
    #       :p4)
    #      ?t)))
    #
    # @see https://www.w3.org/TR/sparql11-query/#sparqlTranslatePathExpressions
    class Path < Operator::Ternary
      include Query
      
      NAME = :path

      ##
      # Finds solutions from `queryable` matching the path.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)
        debug(options) {"Path #{operands.to_sse}"}
        subject, path_op, object = operands

        @solutions = RDF::Query::Solutions.new
        path_op.execute(queryable,
          subject: subject,
          object: object,
          graph_name: options.fetch(:graph_name, false),
          **options.merge(depth: options[:depth].to_i + 1)
        ) do |solution|
          @solutions << solution
        end
        debug(options) {"=> #{@solutions.inspect}"}
        @solutions.uniq!
        @solutions.each(&block) if block_given?
        @solutions
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @param [Boolean] top_level (true)
      #   Treat this as a top-level, generating SELECT ... WHERE {}
      # @return [String]
      def to_sparql(top_level: true, **options)
        str = operands.to_sparql(top_level: false, **options) + " ."
        top_level ? Operator.to_sparql(str, **options) : str
      end

      ##
      # Special cases for optimizing a path based on its operands.
      #
      # @param  [Hash{Symbol => Object}] options
      #   any additional options for optimization
      # @return [SPARQL::Algebra::Operator]
      #   May returnn a different operator
      # @see    RDF::Query#optimize!
      def optimize(**options)
        op = super
        while true
          decon = op.to_sxp_bin
          op = case decon
          # Reverse
          in [:path, subject, [:reverse, path], object]
            Path.new(object, path, subject)
          # Path* (seq (seq p0 (path* p1)) p2)
          in [:path, subject, [:seq, [:seq, p0, [:'path*', p1]], p2], object]
            pp1 = Variable.new(nil, distinguished: false)
            pp2 = Variable.new(nil, distinguished: false)
            pp3 = Variable.new(nil, distinguished: false)
            # Bind variables used in Path*
            bgp = BGP.new(
              Triple.new(pp2, p2, subject),
              Triple.new(object, p1, pp3))
            # New path with pre-bound variables
            path = Path.new(pp3, PathStar.new(p2), pp2)
            Sequence.new(bgp, path)
          else
            # No matching patterns
            break
          end
        end
        op
      end
    end # Path
  end # Operator
end; end # SPARQL::Algebra
