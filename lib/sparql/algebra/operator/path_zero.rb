module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `path0` (ZeroLengthPath) operator.
    #
    # A zero length path matches all subjects and objects in the graph, and also any RDF terms explicitly given as endpoints of the path pattern.
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_evalPP_ZeroOrOnePath
    class PathZero < Operator::Unary
      include Query
      
      NAME = :path0

      ##
      # Zero length path:
      #
      #    (path x (path0 :p) y)
      #     => (filter (x = y) (solution x y))
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
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)
        subject, object = options[:subject], options[:object]
        debug(options) {"PathZero #{[subject, operands, object].to_sse}"}

        solutions = RDF::Query::Solutions.new
        # The zero-length case implies subject == object.
        case
        when subject.variable? && object.variable?
          # Nodes is the set of all subjects and objects in queryable
          query = RDF::Query.new {|q| q.pattern({subject: subject})}
          query.execute(queryable, **options) do |solution|
            solution.merge!(object.to_sym => solution[subject])
            unless solutions.include?(solution)
              #debug(options) {"(solution-s0)-> #{solution.to_h.to_sse}"}
              solutions << solution
            end
          end if query.valid?

          # All objects which are `object`
          query = RDF::Query.new {|q| q.pattern({object: object})}
          query.execute(queryable, **options) do |solution|
            solution.merge!(subject.to_sym => solution[object])
            unless solutions.include?(solution)
              #debug(options) {"(solution-o0)-> #{solution.to_h.to_sse}"}
              solutions << solution
            end
          end if query.valid?
        when subject.variable?
          # All subjects which are `object`
          query = RDF::Query.new {|q| q.pattern({subject: object})}
          query.execute(queryable, **options) do |solution|
            solution.merge!(subject.to_sym => object)
            unless solutions.include?(solution)
              #debug(options) {"(solution-s0)-> #{solution.to_h.to_sse}"}
              solutions << solution
            end
          end if query.valid?

          # All objects which are `object`
          query = RDF::Query.new {|q| q.pattern({object: object})}
          query.execute(queryable, **options) do |solution|
            solution.merge!(subject.to_sym => object)
            unless solutions.include?(solution)
              #debug(options) {"(solution-o0)-> #{solution.to_h.to_sse}"}
              solutions << solution
            end
          end if query.valid?
        when object.variable?
          # All subjects which are `subject`
          query = RDF::Query.new {|q| q.pattern({subject: subject})}
          query.execute(queryable, **options) do |solution|
            solution.merge!(object.to_sym => subject)
            unless solutions.include?(solution)
              #debug(options) {"(solution-s0)-> #{solution.to_h.to_sse}"}
              solutions << solution
            end
          end if query.valid?

          # All objects which are `subject`
          query = RDF::Query.new {|q| q.pattern({object: subject})}
          query.execute(queryable, **options) do |solution|
            solution.merge!(object.to_sym => subject)
            unless solutions.include?(solution)
              #debug(options) {"(solution-o0)-> #{solution.to_h.to_sse}"}
              solutions << solution
            end
          end if query.valid?
        else
          # Otherwise, if subject == object, an empty solution
          solutions << RDF::Query::Solution.new if subject == object
        end

        solutions.uniq!
        debug(options) {"(path0)=> #{solutions.to_sxp}"}
        solutions.each(&block) if block_given?
        solutions
      end
    end # PathZero
  end # Operator
end; end # SPARQL::Algebra
