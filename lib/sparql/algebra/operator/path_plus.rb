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
      # Match on simple relation of subject to object, and then recurse on solutions
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
        debug(options) {"Path+ #{[subject, operands, object].to_sse}"}

        # This turns from
        # (:x :p+ ?y)
        # into
        # (:x :p ?y) UNION solutions(:x :p ?y) do |soln|
        #   if :x.variable?
        #     (soln[:x] :p+ soln[:y])
        # end

        # Solutions where predicate exists
        query = if operand.is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [subject, operand, object]
          end
        else
          operand
        end

        # Block is given on the first invocation, otherwise, results are returned. This is necessary to stop when an existing solution has already been found
        cumulative_solutions = options.fetch(:accumulator, RDF::Query::Solutions.new)

        # Keep track of solutions
        # Recurse into query
        immediate_solutions = []
        queryable.query(query, options.merge(depth: options[:depth].to_i + 1)) do |solution|
          immediate_solutions << solution
        end

        # For all solutions, if they are not in the accumulator, add them and recurse, otherwise skip
        recursive_solutions = RDF::Query::Solutions.new
        immediate_solutions.reject {|s| cumulative_solutions.include?(s)}.each do |solution|
          debug(options) {"(immediate solution)-> #{solution.to_h.to_sse}"}

          # Recurse on subject, if is a variable
          case
          when subject.variable? && object.variable?
            # Query starting with bound object as subject, but replace result with subject
            rs = queryable.query(self, options.merge(
              subject: solution[object],
              accumulator: (cumulative_solutions + immediate_solutions),
              depth: options[:depth].to_i + 1)).map {|s| s.merge(subject.to_sym => solution[subject])}
            # Query starting with bound subject as object, but replace result with subject
            ro = queryable.query(self, options.merge(
              object: solution[subject],
              accumulator: (cumulative_solutions + immediate_solutions),
              depth: options[:depth].to_i + 1)).map {|s| s.merge(object.to_sym => solution[object])}
            recursive_solutions += (rs + ro).uniq
          when subject.variable?
            recursive_solutions += queryable.query(self, options.merge(
              object: solution[subject],
              accumulator: (cumulative_solutions + immediate_solutions),
              depth: options[:depth].to_i + 1)).uniq
          when object.variable?
            recursive_solutions += queryable.query(self, options.merge(
              subject: solution[object],
              accumulator: (cumulative_solutions + immediate_solutions),
              depth: options[:depth].to_i + 1)).uniq
          end
        end
        debug(options) {"(recursive solutions)-> #{recursive_solutions.map(&:to_h).to_sse}"} unless recursive_solutions.empty?

        solutions = (immediate_solutions + recursive_solutions).uniq
        solutions.each(&block) if block_given? # Only at top-level
        solutions
      end
    end # PathPlus
  end # Operator
end; end # SPARQL::Algebra
