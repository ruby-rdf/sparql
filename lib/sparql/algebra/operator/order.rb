module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `order` operator.
    #
    # @example
    #   (prefix ((foaf: <http://xmlns.com/foaf/0.1/>))
    #     (project (?name)
    #       (order ((asc ?name))
    #         (bgp (triple ?x foaf:name ?name)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#modOrderBy
    class Order < Operator::Binary
      include Query
      
      NAME = [:order]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Orders a solution set returned by executing operand(1) using
      # an array of expressions and/or variables specified in operand(0)
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        debug("Order", options)
        @solutions = operands.last.execute(queryable, options.merge(:depth => options[:depth].to_i + 1)).order do |a, b|
          operand(0).inject(false) do |memo, op|
            debug("=> #{op.inspect}", options)
            memo ||= begin
              comp = case op
              when RDF::Query::Variable
                a[op.to_sym] <=> b[op.to_sym]
              when Operator, Array
                a_eval, b_eval = op.evaluate(a), op.evaluate(b)
                if a_eval.nil?
                  RDF::Literal(-1)
                elsif b_eval.nil?
                  RDF::Literal(1)
                else
                  Operator::Compare.evaluate(a_eval, b_eval)
                end
              else
                raise TypeError, "Unexpected order expression #{op.inspect}"
              end
              comp = -comp if op.is_a?(Operator::Desc)
              comp == 0 ? false : comp
            end
          end || 0  # They compare equivalently if there are no matches
        end
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Return optimized query
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        operands = operands.map(&:optimize)
      end
    end # Order
  end # Operator
end; end # SPARQL::Algebra
