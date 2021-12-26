module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `sample` set function.
    #
    # [127] Aggregate::= ... | 'SAMPLE' '(' 'DISTINCT'? Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://www.example.org/>
    #   ASK {
    #     {
    #       SELECT (SAMPLE(?o) AS ?sample)
    #       WHERE { ?s :dec ?o }
    #     }
    #     FILTER(?sample = 1.0 || ?sample = 2.2 || ?sample = 3.5)
    #   }
    #
    # @example SSE
    #   (prefix ((: <http://www.example.org/>))
    #     (filter (|| (|| (= ?sample 1.0) (= ?sample 2.2)) (= ?sample 3.5))
    #       (project (?sample)
    #         (extend ((?sample ??.0))
    #           (group () ((??.0 (sample ?o)))
    #             (bgp (triple ?s :dec ?o)))))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#defn_aggSample
    class Sample < Operator
      include Aggregate

      NAME = :sample

      def initialize(*operands, **options)
        raise ArgumentError,
          "sample operator accepts at most one argument with an optional :distinct" if
          (operands - %i{distinct}).length != 1
        super
      end

      ##
      # Sample is a set function which returns an arbitrary value from the multiset passed to it.
      #
      # @param  [Enumerable<Array<RDF::Term>>] enum
      #   enum of evaluated operand
      # @return [RDF::Term] An arbitrary term
      # @raise  [TypeError] If enum is empty
      def apply(enum, **options)
        enum.detect(lambda {raise TypeError, "Sampling an empty multiset"}) {|e| e.first}.first
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "SAMPLE(#{operands.to_sparql(**options)})"
      end
    end # Sample
  end # Operator
end; end # SPARQL::Algebra
