module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `str` operator.
    #
    # [121] BuiltInCall ::= ... | 'STR' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX  xsd: <http://www.w3.org/2001/XMLSchema#>
    #   PREFIX  : <http://example.org/things#>
    #   SELECT  ?x ?v
    #   WHERE
    #       { ?x :p ?v . 
    #         FILTER ( str(?v) = "1" ) .
    #       }
    #
    # @example SSE
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example.org/things#>))
    #     (project (?x ?v)
    #       (filter (= (str ?v) "1")
    #         (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-str
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
      def apply(term, **options)
        case term
          when RDF::Literal then RDF::Literal(term.value)
          when RDF::URI     then RDF::Literal(term.to_s)
          else raise TypeError, "expected an RDF::Literal or RDF::URI, but got #{term.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "str(" + operands.first.to_sparql(**options) + ")"
      end
    end # Str
  end # Operator
end; end # SPARQL::Algebra
