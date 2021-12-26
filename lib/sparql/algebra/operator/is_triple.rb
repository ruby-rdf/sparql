module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `isTRIPLE` operator.
    #
    # Returns true if term is an RDF-star triple. Returns false otherwise.
    #
    # [121] BuiltInCall ::= ... | 'isTreiple' '(' Expression ')' 
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
    # @see https://w3c.github.io/rdf-star/rdf-star-cg-spec.html#istriple
    class IsTriple < Operator::Unary
      include Evaluatable

      NAME = :isTRIPLE

      ##
      # Returns `true` if the operand is an `RDF::Statement`, `false` otherwise.
      #
      # @param  [RDF::Term] term
      #   an RDF term
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operand is not an RDF term
      def apply(term, **options)
        case term
          when RDF::Statement  then RDF::Literal::TRUE
          when RDF::Term then RDF::Literal::FALSE
          else raise TypeError, "expected an RDF::Term, but got #{term.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "isTRIPLE(" + operands.first.to_sparql(**options) + ")"
      end
    end # IsTriple
  end # Operator
end; end # SPARQL::Algebra
