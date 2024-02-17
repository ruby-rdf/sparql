module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `sequence` operator.
    #
    # Sequences through each operand.
    #
    # [103] CollectionPath          ::= '(' GraphNodePath+ ')'
    #
    # @see https://www.w3.org/TR/sparql11-query/#collections
    class Sequence < Operator
      include SPARQL::Algebra::Update

      NAME = :sequence

      ##
      # Basically a JOIN across multiple operands
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to write
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @option options [Boolean] debug
      #   Query execution debugging
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)
        debug(options) {"Sequence #{operands.to_sse}"}

        last = queryable.query(operands.shift, **options.merge(depth: options[:depth].to_i + 1))
        debug(options) {"(sequence)=>(last) #{last.map(&:to_h).to_sse}"}

        operands.each do |op|
          this = queryable.query(op, **options.merge(depth: options[:depth].to_i + 1))
          debug(options) {"(sequence)=>(this) #{this.map(&:to_h).to_sse}"}

          last = last.map do |s1|
            this.map do |s2|
              s2.merge(s1) if s2.compatible?(s1)
            end
          end.flatten.compact
          debug(options) {"(sequence)=>(next) #{last.map(&:to_h).to_sse}"}
        end

        @solutions = RDF::Query::Solutions.new(last)
        debug(options) {"(sequence)=> #{@solutions.map(&:to_h).to_sse}"}
        @solutions.each(&block) if block_given?
        @solutions
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        str = "{\n" + operands.to_sparql(top_level: false, **options) + "\n}"
        Operator.to_sparql(str, **options)
      end
    end # Sequence
  end # Operator
end; end # SPARQL::Algebra
