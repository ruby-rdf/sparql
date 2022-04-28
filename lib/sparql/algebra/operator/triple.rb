module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `triple` operator.
    #
    # If the 3-tuple (term1, term2, term3) is an RDF-star triple, the function returns this triple. If the 3-tuple is not an RDF-star triple, then the function raises an error.
    #
    # [121] BuiltInCall ::= ... | 'TRIPLE' '(' Expression ',' Expression ',' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.com/ns#>
    #   SELECT * {
    #     ?s ?p ?o .
    #     BIND(TRIPLE(?s, ?p, ?o) AS ?t1)
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://example.com/ns#>))
    #    (extend ((?t1 (triple ?s ?p ?o)))
    #     (bgp (triple ?s ?p ?o))))
    #
    # @note This operator overlaps with RDF::Query::Pattern as used as an operand to a BGP.
    # @see https://w3c.github.io/rdf-star/rdf-star-cg-spec.html#triple
    class Triple < Operator::Ternary
      include Evaluatable

      NAME = :triple

      ##
      # @param  [RDF::Term] subject
      # @param  [RDF::Term] predicate
      # @param  [RDF::Term] object
      # @return [RDF::URI]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(subject, predicate, object, **options)
        triple = RDF::Statement(subject, predicate, object)
        raise TypeError, "valid components, but got #{triple.inspect}" unless triple.valid?
        triple
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "TRIPLE(#{operands.to_sparql(delimiter: ', ', **options)})"
      end
    end # Triple
  end # Operator
end; end # SPARQL::Algebra
