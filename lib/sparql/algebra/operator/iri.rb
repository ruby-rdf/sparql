module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `iri` operator.
    #
    # @example
    #     (base <http://example.org/> (project (?uri ?iri)
    #       (extend ((?uri (uri "uri")) (?iri (iri "iri")))
    #         (bgp))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-iri
    class IRI < Operator::Unary
      include Evaluatable

      NAME = [:iri, :uri]

      ##
      # The IRI function constructs an IRI by resolving the string argument (see RFC 3986 and RFC 3987 or any later RFC that superceeds RFC 3986 or RFC 3987). The IRI is resolved against the base IRI of the query and must result in an absolute IRI.
      # 
      # The URI function is a synonym for IRI.
      # 
      # If the function is passed an IRI, it returns the IRI unchanged.
      # 
      # Passing any RDF term other than a simple literal, xsd:string or an IRI is an error.
      # 
      # An implementation may normalize the IRI.
      #
      # @param  [RDF::Term] literal
      #   a simple literal
      # @return [RDF::URI]
      # @raise  [TypeError] if the operand is not a simple literal
      def apply(literal)
        raise TypeError, "expected an simple literal, but got #{literal.inspect}" unless literal.literal? && literal.simple?
        base = Operator.base_uri || RDF::URI("")
        base.join(literal.to_s)
      end

      Operator::URI = IRI
    end # IRI
  end # Operator
end; end # SPARQL::Algebra
