module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `groupconcat` set function.
    #
    # GroupConcat is a set function which performs a string concatenation across the values of an expression with a group. The order of the strings is not specified. The separator character used in the concatenation may be given with the scalar argument SEPARATOR.
    #
    # @example
    #    (prefix ((: <http://www.example.org/>))
    #      (filter (|| (= ?g "1 22") (= ?g "22 1"))
    #        (project (?g)
    #          (extend ((?g ?.0))
    #            (group () ((?.0 (group_concat ?o)))
    #              (bgp (triple ??0 :p1 ?o)))))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#defn_aggGroupConcat
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
      def aggregate(solutions = [], options = {})
        operands.shift if distinct = (operands.first == :distinct)
        sep = operands.length == 2 ? operand(0).last : RDF::Literal(' ')
        args_enum = solutions.map do |solution|
          begin
            operands.last.evaluate(solution, options.merge(depth: options[:depth].to_i + 1))
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
      def apply(enum, separator)
        RDF::Literal(enum.flatten.map(&:to_s).join(separator.to_s))
      end
    end # GroupConcat
  end # Operator
end; end # SPARQL::Algebra
