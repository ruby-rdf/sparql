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
        debug(options) {"Reverse #{operands.to_sse}"}
        subject, object = options[:subject], options[:object]
      end
    end # Reverse
  end # Operator
end; end # SPARQL::Algebra
