module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `exprlist` operator.
    #
    # Used for filters with more than one expression.
    #
    # [72]  ExpressionList ::= NIL | '(' Expression ( ',' Expression )* ')'
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #
    #   SELECT ?v ?w
    #   { 
    #     FILTER (?v = 2)
    #     FILTER (?w = 3)
    #     ?s :p ?v . 
    #     ?s :q ?w .
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>))
    #     (project (?v ?w)
    #       (filter (exprlist (= ?v 2) (= ?w 3))
    #         (bgp
    #           (triple ?s :p ?v)
    #           (triple ?s :q ?w)
    #         ))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#evaluation
    class Exprlist < Operator
      include Evaluatable

      NAME = [:exprlist]

      ##
      # Returns `true` if all operands evaluate to `true`.
      #
      # Note that this operator operates on the effective boolean value
      # (EBV) of its operands.
      #
      # @example
      #
      #   (exprlist (= 1 1) (!= 1 0))
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operands could not be coerced to a boolean literal
      def evaluate(bindings, **options)
        res = operands.all? {|op| boolean(op.evaluate(bindings, **options.merge(depth: options[:depth].to_i + 1))).true? }
        RDF::Literal(res) # FIXME: error handling
      end
    end # Exprlist
  end # Operator
end; end # SPARQL::Algebra
