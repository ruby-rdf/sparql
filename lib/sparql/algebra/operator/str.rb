module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `str` operator.
    #
    # @example
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (= (str ?v) "1")
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-str
    class Str < Operator::Unary
      include Evaluatable

      NAME = :str

      ##
      # Returns the string form of the operand.
      #
      # @param  [RDF::Literal, RDF::URI] term
      #   a literal or IRI
      # @return [RDF::Literal] a simple literal
      # @raise  [TypeError] if the operand is not a literal or IRI
      def apply(term)
        case term
          when RDF::Literal then RDF::Literal(term.value)
          when RDF::URI     then RDF::Literal(term.to_s)
          else raise TypeError, "expected an RDF::Literal or RDF::URI, but got #{term.inspect}"
        end
      end
    end # Str
  end # Operator
end; end # SPARQL::Algebra
