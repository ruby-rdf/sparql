module SPARQL; module Algebra
  ##
  # Mixin for Algebra::Operator sub-classes that evaluate bindings to return a result
  #
  # @abstract
  module Evaluatable
    ##
    # Evaluates this operator using the given variable `bindings`.
    #
    # @param  [RDF::Query::Solution, #[]] bindings
    #   a query solution containing zero or more variable bindings
    # @return [RDF::Term]
    # @abstract
    def evaluate(bindings = {})
      args = operands.map { |operand| operand.evaluate(bindings) }
      options[:memoize] ? memoize(*args) : apply(*args)
    end

    ##
    # @param  [Array<RDF::Term>] operands
    #   evaluated operands
    # @return [RDF::Term] the memoized result
    def memoize(*operands)
      @cache ||= RDF::Util::Cache.new(options[:memoize].is_a?(Integer) ? options[:memoize] : -1)
      @cache[operands] ||= apply(*operands)
    end

    ##
    # @param  [Array<RDF::Term>] operands
    #   evaluated operands
    # @return [RDF::Term]
    # @abstract
    def apply(*operands)
      raise NotImplementedError, "#{self.class}#apply(#{operands.map(&:class).join(', ')})"
    end
  end # Query
end; end # SPARQL::Algebra
