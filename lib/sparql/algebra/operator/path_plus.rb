module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path+` (OneOrMorePath) operator.
    #
    # @example
    #   (path+ :p)
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_evalPP_OneOrMorePath
    class PathPlus < Operator::Unary
      include Query
      
      NAME = :"path+"

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
        debug(options) {"Path? #{operands.to_sse}"}
        subject, object = options[:subject], options[:object]
      end
    end # PathPlus
  end # Operator
end; end # SPARQL::Algebra
