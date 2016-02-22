module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `datatype` operator.
    #
    # @example
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
    #            (: <http://example.org/>))
    #     (project (?s)
    #       (filter (= (datatype (xsd:double ?v)) xsd:double)
    #         (bgp (triple ?s :p ?v)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-datatype
    class Datatype < Operator::Unary
      include Evaluatable

      NAME = :datatype

      ##
      # Returns the datatype IRI of the operand.
      #
      # If the operand is a simple literal, returns a datatype of
      # `xsd:string`.
      #
      # @param  [RDF::Literal] literal
      #   a typed or simple literal
      # @return [RDF::URI] the datatype IRI, or `xsd:string` for simple literals
      # @raise  [TypeError] if the operand is not a typed or simple literal
      def apply(literal)
        case literal
          when RDF::Literal then literal.datatype
          else raise TypeError, "expected an RDF::Literal, but got #{literal.inspect}"
        end
      end
    end # Datatype
  end # Operator
end; end # SPARQL::Algebra
