module SPARQL; module Algebra
  ##
  # A SPARQL algebra aggregate.
  #
  # Aggregates are for SPARQL set functions. Aggregates take one
  # or more operands which are `Enumerable` lists of `RDF::Term`
  # and return a single `RDF::Term` or `TypeError`.
  #
  # @see http://www.w3.org/TR/sparql11-query/#setFunctions
  # @see http://www.w3.org/TR/sparql11-query/#aggregates
  #
  # @abstract
  module Aggregate
    ##
    # Aggregates this operator accross its operands using
    # a solutions enumerable.
    #
    # The first operand may be :distinct, in which case the result of applying the rest of the operands is uniqued before applying the expression.
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
      args_enum = solutions.map do |solution|
        operands.map do |operand|
          begin
            operand.evaluate(solution, options.merge(depth: options[:depth].to_i + 1))
          rescue TypeError
            # Ignore errors
            nil
          end
        end.compact
      end
      apply(distinct ? args_enum.uniq : args_enum)
    end

    ##
    # @param  [Enumerable<Array<RDF::Term>>] enum
    #   Enumerable yielding evaluated operands
    # @return [RDF::Term]
    # @abstract
    def apply(enum)
      raise NotImplementedError, "#{self.class}#apply(#{operands.map(&:class).join(', ')})"
    end

    ##
    # This is a no-op for Aggregates.
    #
    # @return [SPARQL::Algebra::Evaluatable] self
    def replace_vars!(&block)
      self
    end

    ##
    # Replace ourselves with a variable returned from the block
    #
    # @yield agg
    # @yieldparam [SPARQL::Algebra::Aggregate] agg
    # @yieldreturn [RDF::Query::Variable]
    # @return [RDF::Query::Variable] the returned variable
    def replace_aggregate!(&block)
      yield self
    end
  end # Aggregate
end; end # SPARQL::Algebra
