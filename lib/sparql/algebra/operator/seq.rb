module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Property Path `reverse` (NegatedPropertySet) operator.
    #
    # @example
    #   (seq :a :b)
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
      # @option options [RDF::Term, RDF::Variable] :subject
      # @option options [RDF::Term, RDF::Variable] :object
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
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

        left = queryable.query(q1, options.merge(object: v, depth: options[:depth].to_i + 1))
        debug(options) {"(seq)=>(left) #{left.map(&:to_h).to_sse}"}

        right = queryable.query(q2, options.merge(subject: v, depth: options[:depth].to_i + 1))
        debug(options) {"(seq)=>(right) #{right.map(&:to_h).to_sse}"}

        @solutions = RDF::Query::Solutions(left.map do |s1|
          right.map do |s2|
            s2.merge(s1) if s2.compatible?(s1)
          end
        end.flatten.compact).map do |solution|
          solution.bindings.delete(v.to_sym)
          solution
        end
        debug(options) {"(seq)=> #{@solutions.map(&:to_h).to_sse}"}
        @solutions.each(&block) if block_given?
        @solutions
      end
    end # Seq
  end # Operator
end; end # SPARQL::Algebra
