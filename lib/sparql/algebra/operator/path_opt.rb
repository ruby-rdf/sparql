module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path?` (ZeroOrOnePath) operator.
    #
    # @example
    #   (path? :p)
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_evalPP_ZeroOrOnePath
    class PathOpt < Operator::Unary
      include Query
      
      NAME = :path?

      ##
      # Equivalent to:
      #
      #    `(path x (path? :p) y)`
      #     => `(union (bgp ((x :p y))) (filter (x = x) (solution x y)))`
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

        # Solutions where predicate exists
        pattern = RDF::Query::Pattern.new(subject: subject, predicate: operand, object: object, context: options.fetch(:context, false))
        queryable.execute(pattern, &block)

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
    end # PathOpt
  end # Operator
end; end # SPARQL::Algebra
