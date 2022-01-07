module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL descending sort operator.
    #
    # [24]  OrderCondition          ::= ( ( 'ASC' | 'DESC' ) BrackettedExpression ) | ( Constraint | Var )
    #
    # @example SPARQL Grammar
    #   PREFIX foaf:    <http://xmlns.com/foaf/0.1/>
    #   SELECT ?name
    #   WHERE { ?x foaf:name ?name }
    #   ORDER BY DESC(?name)
    #
    # @example SSE
    #   (prefix ((foaf: <http://xmlns.com/foaf/0.1/>))
    #     (project (?name)
    #       (order ((desc ?name))
    #         (bgp (triple ?x foaf:name ?name)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#modOrderBy
    class Desc < Operator::Asc
      NAME = :desc

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # Provides order to descendant query.
      #
      # @return [String]
      def to_sparql(**options)
        "DESC(#{operands.last.to_sparql(**options)})"
      end
    end # Desc
  end # Operator
end; end # SPARQL::Algebra
