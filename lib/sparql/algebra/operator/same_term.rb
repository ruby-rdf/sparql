module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `sameTerm` operator.
    #
    # @example
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (sameTerm ?v)
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-sameTerm
    class SameTerm < Operator::Binary
      include Evaluatable

      NAME = :sameTerm

      ##
      # Returns `true` if the operands are the same RDF term; returns
      # `false` otherwise.
      #
      # @param  [RDF::Term] term1
      #   an RDF term
      # @param  [RDF::Term] term2
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if either operand is unbound
      def apply(term1, term2)
        RDF::Literal(term1.eql?(term2))
      end

      ##
      # Returns an optimized version of this expression.
      #
      # @return [SPARQL::Algebra::Expression]
      def optimize
        if operand(0).is_a?(Variable) && operand(0).eql?(operand(1))
          RDF::Literal::TRUE
        else
          super # @see Operator#optimize
        end
      end
    end # SameTerm
  end # Operator
end; end # SPARQL::Algebra
