module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `notoneof` (NegatedPropertySet) operator.
    #
    # @example
    #   (notoneof ex:p1 ex:p2)
    #
    # @see http://www.w3.org/TR/sparql11-query/#eval_negatedPropertySet
    class NotOneOf < Operator
      include Query
      
      NAME = :notoneof

      ##
      # Equivalant to:
      #
      #   (path (:x (noteoneof :p :q) :y))
      #   => (filter (notin ??p :p :q) (bgp (:x ??p :y)))
      #
      # @note all operands are terms, and not operators, so this can be done by filtering results usin
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
        debug(options) {"NotOneOf #{operands.to_sse}"}
        subject, object = options[:subject], options[:object]

        v = RDF::Query::Variable.new
        v.distinguished = false
        bgp = RDF::Query.new do |q|
          q.pattern [subject, v, object]
        end
        query = Filter.new(NotIn.new(v, *operands), bgp)
        queryable.query(query, options.merge(depth: options[:depth].to_i + 1)) do |solution|
          solution.bindings.delete(v.to_sym)
          debug(options) {"(solution)-> #{solution.to_h.to_sse}"}
          block.call(solution)
        end
      end
    end # NotOneOf
  end # Operator
end; end # SPARQL::Algebra
