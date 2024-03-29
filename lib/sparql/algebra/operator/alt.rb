module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `alt` (Alternative Property Path) operator.
    #
    # Let P and Q be property path expressions.
    #
    #     eval(Path(X, alt(P,Q), Y)) = Union(eval(Path(X, P, Y)), eval(Path(X, Q, Y)))
    #
    # [89] PathAlternative ::= PathSequence ( '|' PathSequence )*
    #
    # @example SPARQL Query
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
    # @see https://www.w3.org/TR/sparql11-query/#defn_evalPP_alternative
    class Alt < Operator::Binary
      include Query
      
      NAME = :alt

      ##
      # Equivalent to:
      #
      #    (path x (alt :p :q) y)
      #     => (union (bgp (x :p y)) (bgp (x :q y)))
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
        debug(options) {"Alt #{[subject, operands, object].to_sse}"}

        # Solutions where predicate exists
        qa = if operand(0).is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [subject, operand(0), object]
          end
        else
          operand(0)
        end

        qb = if operand(1).is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [subject, operand(1), object]
          end
        else
          operand(1)
        end

        query = Union.new(qa, qb)
        queryable.query(query, **options.merge(depth: options[:depth].to_i + 1), &block)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(#{operands.first.to_sparql(**options)}|#{operands.last.to_sparql(**options)})"
      end
    end # Alt
  end # Operator
end; end # SPARQL::Algebra
