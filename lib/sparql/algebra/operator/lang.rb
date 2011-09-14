module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `lang` operator.
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#func-lang
    class Lang < Operator::Unary
      include Evaluatable

      NAME = :lang

      ##
      # Returns the language tag of the operand, if it has one.
      #
      # If the operand has no language tag, returns `""`.
      #
      # @param  [RDF::Literal] literal
      #   a literal
      # @return [RDF::Literal] a simple literal
      # @raise  [TypeError] if the operand is not a literal
      def apply(literal)
        case literal
          when RDF::Literal then RDF::Literal(literal.language.to_s)
          else raise TypeError, "expected an RDF::Literal, but got #{literal.inspect}"
        end
      end
    end # Lang
  end # Operator
end; end # SPARQL::Algebra
