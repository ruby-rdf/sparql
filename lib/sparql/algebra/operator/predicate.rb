module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `PREDICATE` operator.
    #
    # If triple is an RDF-star triple, the function returns the predicate of this triple. Passing anything other than an RDF-star triple is an error.
    #
    # [121] BuiltInCall ::= ... | 'PREDICATE' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.com/ns#>
    #   SELECT * {
    #     ?t :source :g
    #     FILTER(isTriple(?t))
    #     FILTER(SUBJECT(?t) = :s)
    #     FILTER(PREDICATE(?t) = :p)
    #     FILTER(OBJECT(?t) = :o)
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.com/ns#>))
    #    (filter
    #     (exprlist
    #      (isTRIPLE ?t)
    #      (= (subject ?t) :s)
    #      (= (predicate ?t) :p)
    #      (= (object ?t) :o))
    #     (bgp (triple ?t :source :g))) )
    #
    # @see https://w3c.github.io/rdf-star/rdf-star-cg-spec.html#predicate
    class Predicate < Operator::Unary
      include Evaluatable

      NAME = :predicate

      ##
      # Returns the predicate part of arg.
      #
      # @param  [RDF::Statement] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a statement
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Statement, but got #{operand.inspect}" unless operand.is_a?(RDF::Statement)
        operand.predicate
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "PREDICATE(" + operands.last.to_sparql(**options) + ")"
      end
    end # Predicate
  end # Operator
end; end # SPARQL::Algebra
