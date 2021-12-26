module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `order` operator.
    #
    # [23]  OrderClause             ::= 'ORDER' 'BY' OrderCondition+
    #
    # @example SPARQL Grammar
    #   PREFIX foaf:    <http://xmlns.com/foaf/0.1/>
    #   SELECT ?name
    #   WHERE { ?x foaf:name ?name }
    #   ORDER BY ASC(?name)
    #
    # @example SSE
    #   (prefix ((foaf: <http://xmlns.com/foaf/0.1/>))
    #     (project (?name)
    #       (order ((asc ?name))
    #         (bgp (triple ?x foaf:name ?name)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#modOrderBy
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
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)

        debug(options) {"Order"}
        @solutions = queryable.query(operands.last, depth: options[:depth].to_i + 1, **options).order do |a, b|
          operand(0).inject(0) do |memo, op|
            debug(options) {"(order) #{op.inspect}"}
            memo = begin
              a_eval = op.evaluate(a, queryable: queryable, depth: options[:depth].to_i + 1, **options) rescue nil
              b_eval = op.evaluate(b, queryable: queryable, depth: options[:depth].to_i + 1, **options) rescue nil
              comp = begin
                Operator::Compare.evaluate(a_eval, b_eval, order_by: true).to_s.to_i
              rescue TypeError
                # Type sError is effectively zero
                debug(options) {"(order) rescue(#{$!}): #{a_eval.inspect}, #{b_eval.inspect}"}
                RDF::Literal(0)
              end
              comp = -comp if op.is_a?(Operator::Desc)
              comp
            end if memo == 0
            memo
          end
        end
        @solutions.each(&block) if block_given?
        @solutions
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # Provides order to descendant query.
      #
      # @return [String]
      def to_sparql(**options)
        operands.last.to_sparql(order_ops: operands.first, **options)
      end
    end # Order
  end # Operator
end; end # SPARQL::Algebra
