
module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `function_call` operator.
    #
    # [70]  FunctionCall ::= iri ArgList
    #
    # @example SPARQL Grammar
    #   PREFIX xsd:   <http://www.w3.org/2001/XMLSchema#>
    #   SELECT *
    #   WHERE { ?s ?p ?o . FILTER xsd:integer(?o) }
    #
    # @example SSE
    #   (prefix
    #    ((xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (filter (xsd:integer ?o)
    #     (bgp (triple ?s ?p ?o))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#funcex-regex
    # @see https://www.w3.org/TR/xpath-functions/#func-matches
    class FunctionCall < Operator
      include Evaluatable

      NAME = :function_call

      ##
      # Invokes the function with the passed arguments.
      #
      # @param  [RDF::IRI] iri
      #   Identifies the function
      # @param  [Array<RDF::Term>] args
      # @return [RDF::Term]
      def apply(iri, *args, **options)
        args = RDF.nil == args.last ? args[0..-2] : args
        SPARQL::Algebra::Expression.extension(iri, *args, **options)
      end

      ##
      # Returns the SPARQL S-Expression (SSE) representation of this expression.
      #
      # Remove the optional argument.
      #
      # @return [Array] `self`
      # @see    https://openjena.org/wiki/SSE
      def to_sxp_bin
        @operands.map(&:to_sxp_bin)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        iri, args = operands
        iri.to_sparql(**options) +
          '(' +
          args.to_sparql(delimiter: ', ', **options) +
          ')'
      end
    end # FunctionCall
  end # Operator
end; end # SPARQL::Algebra
