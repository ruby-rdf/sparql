module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `max` set function.
    #
    # [127] Aggregate::= ... | 'MAX' '(' 'DISTINCT'? Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://www.example.org/>
    #   SELECT (MAX(?o) AS ?max)
    #   WHERE { ?s ?p ?o }
    #
    # @example SSE
    #    (prefix ((: <http://www.example.org/>))
    #      (project (?max)
    #        (extend ((?max ??.0))
    #          (group () ((??.0 (max ?o)))
    #            (bgp (triple ?s ?p ?o))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_aggMax
    class Max < Operator
      include Aggregate

      NAME = :max

      def initialize(*operands, **options)
        raise ArgumentError,
          "max operator accepts at most one argument with an optional :distinct" if
          (operands - %i{distinct}).length != 1
        super
      end

      ##
      # Max is a SPARQL set function that return the maximum value from a group respectively.
      #
      # It makes use of the SPARQL ORDER BY ordering definition, to allow ordering over arbitrarily typed expressions.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Literal] The maximum value of the terms
      def apply(enum, **options)
        # FIXME: we don't actually do anything with distinct
        operands.shift if distinct = (operands.first == :distinct)
        if enum.empty?
          raise TypeError, "Maximum of an empty multiset"
        elsif enum.flatten.all? {|n| n.literal?}
          RDF::Literal(enum.flatten.max)
        else
          raise TypeError, "Maximum of non-literals: #{enum.flatten}"
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
        "MAX(#{'DISTINCT ' if distinct}#{args.to_sparql(**options)})"
      end
    end # Max
  end # Operator
end; end # SPARQL::Algebra
