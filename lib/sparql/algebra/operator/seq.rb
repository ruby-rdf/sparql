module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `reverse` (NegatedPropertySet) operator.
    #
    # @example
    #   (Seq :a :b)
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_evalPP_inverse
    class Seq < Operator::Binary
      include Query
      
      NAME = :seq

      ##
      # Join solution sets
      #
      #   (path :x (seq :p :q) :y)
      #   => (join (bgp (:x :p ??1)) (bgp (??1 :q :y)))
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
        subject, object = options[:subject], options[:object]
        debug(options) {"Seq #{[subject, operands, object].to_sse}"}

        v = RDF::Query::Variable.new
        v.distinguished = false
        q1 = if operand(0).is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [subject, operand(0), v]
          end
        else
          operand(0)
        end
        q2 = if operand(1).is_a?(RDF::Term)
          RDF::Query.new do |q|
            q.pattern [v, operand(1), object]
          end
        else
          operand(1)
        end

        queryable.query(Join.new(q1, q2), options.merge(depth: options[:depth].to_i + 1)) do |solution|
          solution.bindings.delete(v.to_sym)
          debug(options) {"(solution)-> #{solution.to_hash.to_sse}"}
          block.call(solution)
        end
      end
    end # Seq
  end # Operator
end; end # SPARQL::Algebra
