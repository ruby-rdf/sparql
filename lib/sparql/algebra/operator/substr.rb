module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL `substr` operator.
    #
    # @example
    #   (substr ?x ?y)
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-substr
    # @see http://www.w3.org/TR/xpath-functions/#func-substring
    class SubStr < Operator::Ternary
      include Evaluatable

      NAME = :substr

      ##
      # Initializes a new operator instance.
      #
      # @param  [RDF::Literal] source
      # @param  [RDF::Litereal::Integer] startingLoc
      # @param  [RDF::Litereal::Integer] length (-1)
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      # @raise  [TypeError] if any operand is invalid
      def initialize(source, startingLoc, length = RDF::Literal(""), options = {})
        super
      end

      ##
      # The substr function corresponds to the XPath fn:substring function and returns a literal of the same kind (simple literal, literal with language tag, xsd:string typed literal) as the source input parameter but with a lexical form formed from the substring of the lexcial form of the source.
      #
      # The arguments startingLoc and length may be derived types of xsd:integer.
      #
      # The index of the first character in a strings is 1.
      #
      # @example
      #     substr("foobar", 4) #=> "bar"
      #     substr("foobar"@en, 4) #=> "bar"@en
      #     substr("foobar"^^xsd:string, 4) #=> "bar"^^xsd:string
      #     substr("foobar", 4, 1) #=> "b"
      #     substr("foobar"@en, 4, 1) #=> "b"@en
      #     substr("foobar"^^xsd:string, 4, 1) #=> "b"^^xsd:string
      #
      # @param  [RDF::Literal] source
      #   a literal
      # @param  [RDF::Literal] startingLoc
      #   an 1-based integer offset into source
      # @param [RDF::Literal::Integer] length (-1)
      #   an optional length of the substring.
      # @return [RDF::Literal]
      # @raise  [TypeError] if operands are not compatible
      def apply(source, startingLoc, length)
        raise TypeError, "expected a plain RDF::Literal, but got #{source.inspect}" unless source.literal? && source.plain?
        text = text.to_s

        raise TypeError, "expected an integer, but got #{startingLoc.inspect}" unless startingLoc.is_a?(RDF::Literal::Integer)
        startingLoc = startingLoc.to_i

        if length == RDF::Literal("")
          RDF::Literal(source.to_s[(startingLoc-1)..-1], datatype: source.datatype, language: source.language)
        else
          raise TypeError, "expected an integer, but got #{length.inspect}" unless length.is_a?(RDF::Literal::Integer)
          length = length.to_i
          RDF::Literal(source.to_s[(startingLoc-1), length], datatype: source.datatype, language: source.language)
        end
      end

      ##
      # Returns the SPARQL S-Expression (SSE) representation of this expression.
      #
      # Remove the optional argument.
      #
      # @return [Array] `self`
      # @see    http://openjena.org/wiki/SSE
      def to_sxp_bin
        [NAME] + operands.reject {|o| o.to_s == ""}
      end
    end # SubStr
  end # Operator
end; end # SPARQL::Algebra
