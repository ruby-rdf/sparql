module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `strlang` operator.
    #
    # @example
    #     (prefix ((: <http://example.org/>))
    #       (project (?s ?s2)
    #         (extend ((?s2 (strlang ?str "en-US")))
    #           (filter (langMatches (lang ?str) "en")
    #             (bgp (triple ?s :str ?str))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-strlang
    class StrLang < Operator::Binary
      include Evaluatable

      NAME = :strlang

      ##
      # Constructs a literal with lexical form and type as specified by the arguments.
      #
      # @param  [RDF::Literal] value
      #   a literal
      # @param  [RDF::Literal] langTag
      #   datatype
      # @return [RDF::Literal] a datatyped literal
      # @see http://www.w3.org/TR/sparql11-query/#func-strlang
      def apply(value, langTag)
        raise TypeError, "Literal #{value.inspect} is not simple" unless value.simple?
        RDF::Literal.new(value.to_s, language: langTag.to_s)
      end
    end # StrLang
  end # Operator
end; end # SPARQL::Algebra
