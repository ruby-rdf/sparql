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
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-datatype
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
          when RDF::Literal then case
            when literal.typed?  then RDF::URI(literal.datatype)
            when literal.simple? then RDF::XSD.string
            else raise TypeError, "expected a typed or simple RDF::Literal, but got #{literal.inspect}"
          end
          else raise TypeError, "expected an RDF::Literal, but got #{literal.inspect}"
        end
      end
    end # Datatype
  end # Operator
end; end # SPARQL::Algebra
