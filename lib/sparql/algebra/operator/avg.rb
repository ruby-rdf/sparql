module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `avg` set function.
    #
    # @example
    #    (prefix ((: <http://www.example.org/>))
    #      (project (?avg)
    #        (extend ((?avg ??.0))
    #          (group () ((??.0 (avg ?o)))
    #            (bgp (triple ?s :dec ?o))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_aggAvg
    class Avg < Operator
      include Aggregate

      NAME = :avg

      def initialize(*operands, **options)
        raise ArgumentError,
          "avg operator accepts at most one argument with an optional :distinct" if
          (operands - %i{distinct}).length != 1
        super
      end

      ##
      # The Avg set function calculates the average value for an expression over a group. It is defined in terms of Sum and Count.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Literal::Numeric] The numeric average of the terms
      def apply(enum, **options)
        # FIXME: we don't actually do anything with distinct
        operands.shift if distinct = (operands.first == :distinct)
        if enum.empty?
          RDF::Literal(0)
        elsif enum.flatten.all? {|n| n.is_a?(RDF::Literal::Numeric)}
          enum.flatten.reduce(:+) / RDF::Literal::Decimal.new(enum.length)
        else
          raise TypeError, "Averaging non-numeric types: #{enum.flatten}"
        end
      end
    end # Avg
  end # Operator
end; end # SPARQL::Algebra
