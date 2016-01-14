module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `replace` operator.
    #
    # @example
    #     (prefix ((: <http://example.org/>)
    #              (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #       (project (?s ?new)
    #         (extend ((?new (replace ?str "[^a-z0-9]" "-")))
    #           (bgp (triple ?s :str ?str)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#funcex-replace
    # @see http://www.w3.org/TR/xpath-functions/#func-replace
    class Replace < Operator::Quaternary
      include Evaluatable

      NAME = :replace

      ##
      # Initializes a new operator instance.
      #
      # @param  [RDF::Literal] text
      # @param  [RDF::Literal] pattern
      # @param  [RDF::Literal] replacement
      # @param  [RDF::Literal] flags
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      # @raise  [TypeError] if any operand is invalid
      def initialize(text, pattern, replacement, flags = RDF::Literal(''), options = {})
        super
      end

      ##
      # Matches `text` against a regular expression `pattern`.
      #
      # @param  [RDF::Literal] text a simple literal
      # @param  [RDF::Literal] pattern a simple literal
      # @param  [RDF::Literal] replacement
      # @param  [RDF::Literal] flags
      #   a simple literal (defaults to an empty string)
      # @return [RDF::Literal] 
      # @raise  [TypeError] if any operand is unbound
      # @raise  [TypeError] if any operand is not a plain literal
      def apply(text, pattern, replacement, flags = RDF::Literal(''))
        raise TypeError, "expected a plain RDF::Literal, but got #{text.inspect}" unless text.literal? && text.plain?
        # TODO: validate text syntax

        raise TypeError, "expected a plain RDF::Literal, but got #{pattern.inspect}" unless pattern.literal? && pattern.plain?
        pattern = pattern.to_s
        # TODO: validate pattern syntax

        raise TypeError, "expected a plain RDF::Literal, but got #{replacement.inspect}" unless replacement.literal? && replacement.plain?
        replacement = replacement.to_s.gsub('$', '\\')  # Replace references
        # TODO: validate flag syntax

        raise TypeError, "expected a plain RDF::Literal, but got #{flags.inspect}" unless flags.literal? && flags.plain?
        flags = flags.to_s
        # TODO: validate flag syntax

        options = 0
        raise NotImplementedError, "unsupported regular expression flag: /s" if flags.include?(?s) # FIXME
        options |= Regexp::MULTILINE  if flags.include?(?m)
        options |= Regexp::IGNORECASE if flags.include?(?i)
        options |= Regexp::EXTENDED   if flags.include?(?x)
        RDF::Literal(text.to_s.gsub(Regexp.new(pattern, options), replacement), datatype: text.datatype, language: text.language)
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
    end # Replace
  end # Operator
end; end # SPARQL::Algebra
