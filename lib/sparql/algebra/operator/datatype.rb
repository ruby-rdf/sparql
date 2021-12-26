module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `datatype` operator.
    #
    # [121] BuiltInCall ::= ... | 'DATATYPE' '(' Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX  xsd: <http://www.w3.org/2001/XMLSchema#>
    #   PREFIX  : <http://example.org/things#>
    #   SELECT  ?x ?v
    #   WHERE
    #       { ?x :p ?v . 
    #         FILTER ( datatype(?v) = xsd:double ) .
    #       }
    #
    # @example SSE
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example.org/things#>))
    #    (project (?x ?v)
    #     (filter (= (datatype ?v) xsd:double)
    #      (bgp (triple ?x :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-datatype
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
      def apply(literal, **options)
        case literal
          when RDF::Literal then literal.datatype
          else raise TypeError, "expected an RDF::Literal, but got #{literal.inspect}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "DATATYPE(#{operands.last.to_sparql(**options)})"
      end
    end # Datatype
  end # Operator
end; end # SPARQL::Algebra
