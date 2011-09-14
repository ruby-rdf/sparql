module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL ascending sort operator.
    #
    # @example
    #   (prefix ((foaf: <http://xmlns.com/foaf/0.1/>))
    #     (project (?name)
    #       (order ((asc ?name))
    #         (bgp (triple ?x foaf:name ?name)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-isLiteral
    class Asc < Operator::Unary
      include Evaluatable

      NAME = :asc

      ##
      # Returns the evaluation of it's operand. Default comparison is in
      # ascending order. Ordering is applied in {Order}.
      #
      # @param  [RDF::Query::Solution, #[]] bindings
      # @return [RDF::Term]
      def evaluate(bindings = {})
        operand(0).evaluate(bindings)
      end
    end # Asc
  end # Operator
end; end # SPARQL::Algebra
