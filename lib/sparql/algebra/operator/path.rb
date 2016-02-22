module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path` operator.
    #
    # @example
    #   (path :a (path+ :p) ?z)
    #
    # @see http://www.w3.org/TR/sparql11-query/#sparqlTranslatePathExpressions
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
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, options = {}, &block)
        debug(options) {"Path #{operands.to_sse}"}
        subject, path_op, object = operands

        @solutions = RDF::Query::Solutions.new
        path_op.execute(queryable, options.merge(
          subject: subject,
          object: object,
          graph_name: options.fetch(:graph_name, false),
          depth: options[:depth].to_i + 1)
        ) do |solution|
          @solutions << solution
        end
        debug(options) {"=> #{@solutions.inspect}"}
        @solutions.uniq!
        @solutions.each(&block) if block_given?
        @solutions
      end
    end # Path
  end # Operator
end; end # SPARQL::Algebra
