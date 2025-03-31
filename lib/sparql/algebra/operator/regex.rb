module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `regex` operator.
    #
    # [122] RegexExpression         ::= 'REGEX' '(' Expression ',' Expression ( ',' Expression )? ')'
    #
    # @example SPARQL Grammar
    #   PREFIX  ex: <http://example.com/#>
    #   PREFIX  rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    #   SELECT ?val
    #   WHERE {
    #     ex:foo rdf:value ?val .
    #     FILTER regex(?val, "GHI")
    #   }
    #
    # @example SSE
    #   (prefix ((ex: <http://example.com/#>)
    #            (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>))
    #    (project (?val)
    #     (filter (regex ?val "GHI")
    #      (bgp (triple ex:foo rdf:value ?val)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#funcex-regex
    # @see https://www.w3.org/TR/xpath-functions/#func-matches
    class Regex < Operator
      include Evaluatable

      NAME = :regex

      ##
      # Matches `text` against a regular expression `pattern`.
      #
      # @param  [RDF::Literal] text
      #   a simple literal
      # @param  [RDF::Literal] pattern
      #   a simple literal
      # @param  [RDF::Literal] flags
      #   a simple literal (defaults to an empty string)
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if any operand is unbound
      # @raise  [TypeError] if any operand is not a simple literal
      def apply(text, pattern, flags = RDF::Literal(''), **options)
        # @see https://www.w3.org/TR/xpath-functions/#regex-syntax
        raise TypeError, "expected a plain RDF::Literal, but got #{text.inspect}" unless text.is_a?(RDF::Literal) && text.plain?
        text = text.to_s
        # TODO: validate text syntax

        # @see https://www.w3.org/TR/xpath-functions/#regex-syntax
        raise TypeError, "expected a plain RDF::Literal, but got #{pattern.inspect}" unless pattern.is_a?(RDF::Literal) && pattern.plain?
        pattern = pattern.to_s
        # TODO: validate pattern syntax

        # @see https://www.w3.org/TR/xpath-functions/#flags
        raise TypeError, "expected a plain RDF::Literal, but got #{flags.inspect}" unless flags.is_a?(RDF::Literal) && flags.plain?
        flags = flags.to_s
        # TODO: validate flag syntax

        # 's' mode in XPath is like ruby MUTLILINE
        # 'm' mode in XPath is like ruby /^$/ vs /\A\z/
        unless flags.include?(?m)
          pattern = '\A' + pattern[1..-1] if pattern.start_with?('^')
          pattern = pattern[0..-2] + '\z' if pattern.end_with?('$')
        end

        options = 0
        %w(q x).each do |flag|
          raise NotImplementedError, "unsupported regular expression flag: /#{flag}" if flags.include?(flag) # FIXME
        end
        options |= Regexp::MULTILINE  if flags.include?(?s) # dot-all mode
        options |= Regexp::IGNORECASE if flags.include?(?i)
        RDF::Literal(Regexp.new(pattern, options) === text)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        ops = operands.last.to_s.empty? ? operands[0..-2] : operands
        "regex(" + ops.to_sparql(delimiter: ', ', **options) + ")"
      end
    end # Regex
  end # Operator
end; end # SPARQL::Algebra
