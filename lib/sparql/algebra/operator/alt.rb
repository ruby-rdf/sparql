module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `alt` (Alternative Property Path) operator.
    #
    # @example
    #   (alt a b)
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_evalPP_alternative
    class Alt < Operator::Binary
      include Query
      
      NAME = :alt

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
        debug(options) {"Alt #{operands.to_sse}"}
        subject, object = options[:subject], options[:object]
      end
    end # Alt
  end # Operator
end; end # SPARQL::Algebra
