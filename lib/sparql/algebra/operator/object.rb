module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `OBJECT` operator.
    #
    # If triple is an RDF-star triple, the function returns the object of this triple. Passing anything other than an RDF-star triple is an error.
    #
    # [121] BuiltInCall ::= ... | 'OBJECT' '(' Expression ')' 
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
    # @see https://w3c.github.io/rdf-star/rdf-star-cg-spec.html#object
    class Object < Operator::Unary
      include Evaluatable

      NAME = :object

      ##
      # Returns the object part of arg.
      #
      # @param  [RDF::Statement] operand
      #   the operand
      # @return [RDF::Literal]
      # @raise  [TypeError] if the operand is not a statement
      def apply(operand, **options)
        raise TypeError, "expected an RDF::Statement, but got #{operand.inspect}" unless operand.is_a?(RDF::Statement)
        operand.object
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "OBJECT(" + operands.last.to_sparql(**options) + ")"
      end
    end # Object
  end # Operator
end; end # SPARQL::Algebra
