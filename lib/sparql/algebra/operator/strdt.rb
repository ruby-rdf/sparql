module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `strdt` operator.
    #
    # @example
    #     (project (?s ?str1)
    #       (extend ((?str1 (strdt ?str xsd:string)))
    #         (filter (langMatches (lang ?str) "en")
    #           (bgp (triple ?s :str ?str))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-strdt
    class StrDT < Operator::Binary
      include Evaluatable

      NAME = :strdt

      ##
      # Constructs a literal with lexical form and type as specified by the arguments.
      #
      # @param  [RDF::Literal] value
      #   a literal
      # @param  [RDF::URI] datatypeIRI
      #   datatype
      # @return [RDF::Literal] a datatyped literal
      # @see http://www.w3.org/TR/sparql11-query/#func-strdt
      def apply(value, datatypeIRI)
        raise TypeError, "Literal #{value.inspect} is not simple" unless value.simple?
        RDF::Literal.new(value.to_s, datatype: datatypeIRI)
      end
    end # StrDT
  end # Operator
end; end # SPARQL::Algebra
