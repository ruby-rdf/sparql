module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path*` (ZeroOrMorePath) operator.
    #
    # @example
    #   (path* :p)
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_evalPP_ZeroOrMorePath
    class PathStar < Operator::Unary
      include Query
      
      NAME = :"path*"

      ##
      # Solutions are the unique subjects and objects in `queryable` as with `path?` plus the results of `path+`
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
        debug(options) {"Path* #{operands.to_sse}"}
        subject, object = options[:subject], options[:object]

        plus = PathPlus.new(*operands)
        plus.execute(queryable, options.merge(depth: options[:depth].to_i + 1), &block)

        # Solutions where subject == object
        nodes = []
        case
        when subject.variable? && object.variable?
          # Nodes is the set of all subjects and objects in queryable
          # FIXME: should this be Queryable#enum_nodes?
          queryable.query(subject: subject, context: options.fetch(:context, false)).each do |solution|
            nodes << solution.merge!(object => solution[subject])
          end
          queryable.query(object: subject, context: options.fetch(:context, false)).each do |solution|
            nodes << solution.merge!(object => solution[subject])
          end
        when subject.variable?
          queryable.query(subject: object, context: options.fetch(:context, false)).each do |solution|
            nodes << solution.merge!(subject => object)
          end
          queryable.query(object: object, context: options.fetch(:context, false)).each do |solution|
            nodes << solution.merge!(subject => object)
          end
        when object.variable?
          queryable.query(subject: subject, context: options.fetch(:context, false)).each do |solution|
            nodes << solution.merge!(object => subject)
          end
          queryable.query(object: subject, context: options.fetch(:context, false)).each do |solution|
            nodes << solution.merge!(object => subject)
          end
        else
          # Otherwise, if subject == object, an empty solution
          nodes << RDF::Query::Solution.new if subject == object
        end
        # Yield each solution only once
        nodes.uniq.each(&block)
      end
    end # PathStar
  end # Operator
end; end # SPARQL::Algebra
