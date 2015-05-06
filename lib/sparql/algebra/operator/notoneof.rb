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
      # XXX
      #        
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @param [RDF::Term, RDF::Variable] :subject
      # @param [RDF::Term, RDF::Variable] :object
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {}, &block)
        debug(options) {"NotOneOf #{operands.to_sse}"}
        subject, object = options[:subject], options[:object]
      end
    end # NotOneOf
  end # Operator
end; end # SPARQL::Algebra
