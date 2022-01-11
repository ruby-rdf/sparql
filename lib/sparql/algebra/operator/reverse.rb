module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `reverse` (NegatedPropertySet) operator.
    #
    # [92]  PathEltOrInverse        ::= PathElt | '^' PathElt
    #
    # @example SPARQL Grammar
    #   PREFIX ex:	<http://www.example.org/schema#>
    #   PREFIX in:	<http://www.example.org/instance#>
    #   ASK { in:b ^ex:p in:a }
    #
    # @example SSE
    #   (prefix ((ex: <http://www.example.org/schema#>)
    #            (in: <http://www.example.org/instance#>))
    #    (ask (path in:b (reverse ex:p) in:a)))
    #
    # @example SPARQL Grammar
    #   prefix ex:	<http://www.example.org/schema#>
    #   prefix in:	<http://www.example.org/instance#>
    #   
    #   select  * where { in:c ^(ex:p1/ex:p2) ?x }
    #
    # @example SSE
    #   (prefix ((ex: <http://www.example.org/schema#>)
    #            (in: <http://www.example.org/instance#>))
    #    (path in:c (reverse (seq ex:p1 ex:p2)) ?x))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_evalPP_inverse
    class Reverse < Operator::Unary
      include Query
      
      NAME = :reverse

      ##
      # Equivliant to:
      #
      #   (path (:a (reverse :p) :b))
      #   => (bgp (:b :p :a))
      #        
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
        debug(options) {"Reverse #{operands.to_sse}"}
        subject, object = options[:subject], options[:object]

        # Solutions where predicate exists
        query = if operand.is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [object, operand, subject]
          end
        else
          operand(0)
        end
        queryable.query(query, **options.merge(
          subject: object,
          object: subject,
          depth: options[:depth].to_i + 1
        ), &block)

      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "^(" + operands.first.to_sparql(**options) + ')'
      end
    end # Reverse
  end # Operator
end; end # SPARQL::Algebra
