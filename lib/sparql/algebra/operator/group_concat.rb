module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `groupconcat` set function.
    #
    # GroupConcat is a set function which performs a string concatenation across the values of an expression with a group. The order of the strings is not specified. The separator character used in the concatenation may be given with the scalar argument SEPARATOR.
    #
    # If all operands are language-tagged strings with the same language (and direction), the result shares the language (and direction).
    #
    # [127] Aggregate::= ... | 'GROUP_CONCAT' '(' 'DISTINCT'? Expression ( ';' 'SEPARATOR' '=' String )? ')'
    #
    # @example SPARQL Grammar
    #   SELECT (GROUP_CONCAT(?x) AS ?y) {}
    #
    # @example SSE
    #   (project (?y)
    #    (extend ((?y ??.0))
    #     (group () ((??.0 (group_concat ?x)))
    #      (bgp))))
    #
    # @example SPARQL Grammar (DISTINCT)
    #   SELECT (GROUP_CONCAT(DISTINCT ?x) AS ?y) {}
    #
    # @example SSE (DISTINCT)
    #   (project (?y)
    #    (extend ((?y ??.0))
    #     (group () ((??.0 (group_concat distinct ?x)))
    #      (bgp))))
    #
    # @example SPARQL Grammar (SEPARATOR)
    #   SELECT (GROUP_CONCAT(?x; SEPARATOR=';') AS ?y) {}
    #
    # @example SSE (SEPARATOR)
    #   (project (?y)
    #    (extend ((?y ??.0))
    #     (group () ((??.0 (group_concat (separator ";") ?x)))
    #      (bgp))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_aggGroupConcat
    class GroupConcat < Operator
      include Aggregate

      NAME = :group_concat

      ##
      # One, two or three operands, the first may be `distinct`, the last operand, if it exists, is a separator, defaulting to ' '.
      #
      # @param  [Enumerable<RDF::Query::Solution>] solutions ([])
      #   an enumerable set of query solutions
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @return [RDF::Term]
      # @raise [TypeError]
      # @abstract
      def aggregate(solutions = [], **options)
        operands.shift if distinct = (operands.first == :distinct)
        sep = operands.length == 2 ? operand(0).last : RDF::Literal(' ')
        args_enum = solutions.map do |solution|
          begin
            operands.last.evaluate(solution, **options.merge(depth: options[:depth].to_i + 1))
          rescue TypeError
            # Ignore errors
            nil
          end
        end
        apply(distinct ? args_enum.uniq : args_enum, sep)
      end

      ##
      # GroupConcat is a set function which performs a string concatenation across the values of an expression with a group. The order of the strings is not specified. The separator character used in the concatenation may be given with the scalar argument SEPARATOR.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Term] An arbitrary term
      # @raise  [TypeError] If enum is empty
      def apply(enum, separator, **options)
        op1_lang = enum.first.language
        lang = op1_lang if op1_lang && enum.all? {|v| v.language == op1_lang}
        RDF::Literal(enum.flatten.map(&:to_s).join(separator.to_s), language: lang)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        distinct = operands.first == :distinct
        args = distinct ? operands[1..-1] : operands
        separator = args.first.last if args.first.is_a?(Array) && args.first.first == :separator
        args = args[1..-1] if separator
        str = "GROUP_CONCAT(#{'DISTINCT ' if distinct}#{args.to_sparql(delimiter: ', ', **options)}"
        str << "; SEPARATOR=#{separator.to_sparql}" if separator
        str << ")"
      end
    end # GroupConcat
  end # Operator
end; end # SPARQL::Algebra
