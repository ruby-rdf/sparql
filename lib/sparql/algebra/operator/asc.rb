module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL ascending sort operator.
    #
    # [24]  OrderCondition          ::= ( ( 'ASC' | 'DESC' ) BrackettedExpression ) | ( Constraint | Var )
    #
    # @example SPARQL Query
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
    class Asc < Operator::Unary
      include Evaluatable

      NAME = :asc

      ##
      # Returns the evaluation of its operand. Default comparison is in
      # ascending order. Ordering is applied in {Order}.
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @return [RDF::Term]
      def evaluate(bindings, **options)
        operand(0).evaluate(bindings, **options.merge(depth: options[:depth].to_i + 1))
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # Provides order to descendant query.
      #
      # @return [String]
      def to_sparql(**options)
        "ASC(#{operands.last.to_sparql(**options)})"
      end
    end # Asc
  end # Operator
end; end # SPARQL::Algebra
