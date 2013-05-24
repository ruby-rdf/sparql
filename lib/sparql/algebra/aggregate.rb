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
    # @param  [Enumerable<RDF::Query::Solution>] solutions ([])
    #   an enumerable set of query solutions
    # @return [RDF::Term]
    # @raise [TypeError]
    # @abstract
    def aggregate(solutions = [])
      args_enum = solutions.map {|bindings| operands.map {|operand| operand.evaluate(bindings)}}
      apply(args_enum)
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
  end # Aggregate
end; end # SPARQL::Algebra
