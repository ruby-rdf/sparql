module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `reverse` (NegatedPropertySet) operator.
    #
    # @example
    #   (reverse :p)
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_evalPP_inverse
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
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, options = {}, &block)
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
        queryable.query(query, options.merge(
          subject: object,
          object: subject,
          depth: options[:depth].to_i + 1
        ), &block)

      end
    end # Reverse
  end # Operator
end; end # SPARQL::Algebra
