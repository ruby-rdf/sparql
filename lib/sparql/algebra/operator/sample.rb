module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `sample` set function.
    #
    # [127] Aggregate::= ... | 'SAMPLE' '(' 'DISTINCT'? Expression ')' 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example/>
    #   
    #   SELECT ?w (SAMPLE(?v) AS ?S)
    #   {
    #     ?s :p ?v .
    #     OPTIONAL { ?s :q ?w }
    #   }
    #   GROUP BY ?w
    #
    # @example SSE
    #   (prefix ((: <http://example/>))
    #    (project (?w ?S)
    #     (extend ((?S ??.0))
    #      (group (?w) ((??.0 (sample ?v)))
    #       (leftjoin
    #        (bgp (triple ?s :p ?v))
    #         (bgp (triple ?s :q ?w))))) ))
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
        distinct = operands.first == :distinct
        args = distinct ? operands[1..-1] : operands
        "SAMPLE(#{'DISTINCT ' if distinct}#{args.to_sparql(**options)})"
      end
    end # Sample
  end # Operator
end; end # SPARQL::Algebra
