module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL `concat` operator.
    #
    # @example
    #   (concat ?a ?b)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-concat
    # @see http://www.w3.org/TR/xpath-functions/#func-concat
    class Concat < Operator::Binary
      include Evaluatable

      NAME = :concat

      ##
      # The lexical form of the returned literal is obtained by concatenating the lexical forms of its inputs. If all input literals are typed literals of type xsd:string, then the returned literal is also of type xsd:string, if all input literals are plain literals with identical language tag, then the returned literal is a plain literal with the same language tag, in all other cases, the returned literal is a simple literal.
      #
      # @example
      #     concat("foo", "bar")                         #=> "foobar"
      #     concat("foo"@en, "bar"@en)                   #=> "foobar"@en
      #     concat("foo"^^xsd:string, "bar"^^xsd:string) #=> "foobar"^^xsd:string
      #     concat("foo", "bar"^^xsd:string)             #=> "foobar"
      #     concat("foo"@en, "bar")                      #=> "foobar"
      #     concat("foo"@en, "bar"^^xsd:string)          #=> "foobar"
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal] 
      # @raise  [TypeError] if either operand is not a literal
      def apply(left, right)
        case
        when !left.literal? || !right.literal?
          raise TypeError, "expected two plain literal operands, but got #{left.inspect} and #{right.inspect}"
        when ![left.datatype, right.datatype].compact.all? {|dt| dt == RDF::XSD.string}
          raise TypeError, "expected two plain literal operands, but got #{left.inspect} and #{right.inspect}"
        when left.datatype == RDF::XSD.string && right.datatype == RDF::XSD.string
          RDF::Literal.new("#{left}#{right}", :datatype => RDF::XSD.string)
        when left.has_language? && left.language == right.language
          RDF::Literal.new("#{left}#{right}", :language => left.language)
        else
          RDF::Literal.new("#{left}#{right}")
        end
      end
    end # Concat
  end # Operator
end; end # SPARQL::Algebra
