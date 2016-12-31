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
      #    (path x (path? :p) y)
      #     => (union (bgp ((x :p y))) (filter (x = x) (solution x y)))
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
        subject, object = options[:subject], options[:object]
        debug(options) {"Path? #{[subject, operands, object].to_sse}"}

        solutions = RDF::Query::Solutions.new
        # Solutions where subject == object with no predicate
        case
        when subject.variable? && object.variable?
          # Nodes is the set of all subjects and objects in queryable
          # FIXME: should this be Queryable#enum_nodes?
          # All subjects which are `object`
          query = RDF::Query.new {|q| q.pattern(subject: subject)}
          queryable.query(query, options) do |solution|
            solution.merge!(object.to_sym => solution[subject])
            debug(options) {"(solution-s0)-> #{solution.to_h.to_sse}"}
            solutions << solution
          end if query.valid?

          # All objects which are `object`
          query = RDF::Query.new {|q| q.pattern(object: object)}
          queryable.query(query, options) do |solution|
            solution.merge!(subject.to_sym => solution[object])
            debug(options) {"(solution-o0)-> #{solution.to_h.to_sse}"}
            solutions << solution
          end if query.valid?
        when subject.variable?
          # All subjects which are `object`
          query = RDF::Query.new {|q| q.pattern(subject: object)}
          queryable.query(query, options) do |solution|
            solution.merge!(subject.to_sym => object)
            debug(options) {"(solution-s0)-> #{solution.to_h.to_sse}"}
            solutions << solution
          end if query.valid?

          # All objects which are `object`
          query = RDF::Query.new {|q| q.pattern(object: object)}
          queryable.query(query, options) do |solution|
            solution.merge!(subject.to_sym => object)
            debug(options) {"(solution-o0)-> #{solution.to_h.to_sse}"}
            solutions << solution
          end if query.valid?
        when object.variable?
          # All subjects which are `subject`
          query = RDF::Query.new {|q| q.pattern(subject: subject)}
          queryable.query(query, options) do |solution|
            solution.merge!(object.to_sym => subject)
            debug(options) {"(solution-s0)-> #{solution.to_h.to_sse}"}
            solutions << solution
          end if query.valid?

          # All objects which are `subject
          query = RDF::Query.new {|q| q.pattern(object: subject)}
          queryable.query(query, options) do |solution|
            solution.merge!(object.to_sym => subject)
            debug(options) {"(solution-o0)-> #{solution.to_h.to_sse}"}
            solutions << solution
          end if query.valid?
        else
          # Otherwise, if subject == object, an empty solution
          solutions << RDF::Query::Solution.new if subject == object
        end

        # Solutions where predicate exists
        query = if operand.is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [subject, operand, object]
          end
        else
          operand
        end

        # Recurse into query
        solutions += 
        queryable.query(query, options.merge(depth: options[:depth].to_i + 1))
        solutions.each(&block) if block_given?
        solutions
      end
    end # PathOpt
  end # Operator
end; end # SPARQL::Algebra
