module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `count` set function.
    #
    # [127] Aggregate::= 'COUNT' '(' 'DISTINCT'? ( '*' | Expression ) ')' ...
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://www.example.org/>
    #   SELECT (COUNT(?O) AS ?C)
    #   WHERE { ?S ?P ?O }
    #
    # @example SSE
    #   (prefix ((: <http://www.example.org/>))
    #     (project (?C)
    #       (extend ((?C ??.0))
    #         (group () ((??.0 (count ?O)))
    #           (bgp (triple ?S ?P ?O))))))
    #
    # @example SPARQL Grammar (count(*))
    #   PREFIX : <http://www.example.org>
    #   
    #   SELECT (COUNT(*) AS ?C)
    #   WHERE { ?S ?P ?O }
    #
    # @example SSE (count(*))
    #   (prefix
    #    ((: <http://www.example.org>))
    #    (project (?C)
    #     (extend ((?C ??.0))
    #      (group () ((??.0 (count)))
    #       (bgp (triple ?S ?P ?O))))))
    #
    # @example SPARQL Grammar (count(distinct *))
    #   PREFIX : <http://www.example.org>
    #   
    #   SELECT (COUNT(DISTINCT *) AS ?C)
    #   WHERE { ?S ?P ?O }
    #
    # @example SSE (count(distinct *))
    #   (prefix
    #    ((: <http://www.example.org>))
    #    (project (?C)
    #     (extend ((?C ??.0))
    #      (group () ((??.0 (count distinct)))
    #       (bgp (triple ?S ?P ?O))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_aggCount
    class Count < Operator
      include Aggregate

      NAME = :count

      ##
      # Count is a SPARQL set function which counts the number of times a given expression has a bound, and non-error value within the aggregate group.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Literal::Integer] The number of non-error terms in the multiset
      def apply(enum, **options)
        RDF::Literal(enum.length)
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        distinct = operands.first == :distinct
        args = distinct ? operands[1..-1] : operands
        "COUNT(#{'DISTINCT ' if distinct}#{args.empty? ? '*' : args.to_sparql(**options)})"
      end
    end # Count
  end # Operator
end; end # SPARQL::Algebra
