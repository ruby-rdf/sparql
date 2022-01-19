module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `sum` set function.
    #
    # [127] Aggregate::= ... | 'SUM' '(' 'DISTINCT'? Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://www.example.org/>
    #   SELECT (SUM(?o) AS ?sum)
    #   WHERE { ?s :dec ?o }
    #
    # @example SSE
    #   (prefix ((: <http://www.example.org/>))
    #     (project (?sum)
    #       (extend ((?sum ??.0))
    #         (group () ((??.0 (sum ?o)))
    #           (bgp (triple ?s :dec ?o))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_aggSum
    class Sum < Operator
      include Aggregate

      NAME = :sum

      ##
      # Sum is a SPARQL set function that will return the numeric value obtained by summing the values within the aggregate group. Type promotion happens as per the op:numeric-add function, applied transitively, (see definition below) so the value of SUM(?x), in an aggregate group where ?x has values 1 (integer), 2.0e0 (float), and 3.0 (decimal) will be 6.0 (float).
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Literal::Numeric] The sum of the terms
      def apply(enum, **options)
        # FIXME: we don't actually do anything with distinct
        operands.shift if distinct = (operands.first == :distinct)
        if enum.empty?
          RDF::Literal(0)
        elsif enum.flatten.all? {|n| n.is_a?(RDF::Literal::Numeric)}
          enum.flatten.reduce(:+)
        else
          raise TypeError, "Averaging non-numeric types: #{enum.flatten}"
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        distinct = operands.first == :distinct
        args = distinct ? operands[1..-1] : operands
        "SUM(#{'DISTINCT ' if distinct}#{args.to_sparql(**options)})"
      end
    end # Sum
  end # Operator
end; end # SPARQL::Algebra
