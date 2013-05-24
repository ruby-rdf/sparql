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

    ##
    # Replace operators which are variables with the result of the block
    # descending into operators which are also evaluatable
    #
    # @yield var
    # @yieldparam [RDF::Query::Variable] var
    # @yieldreturn [RDF::Query::Variable, SPARQL::Algebra::Evaluatable]
    # @return [SPARQL::Algebra::Evaluatable] self
    def replace_vars!(&block)
      operands = operands.map! do |op|
        case
        when op.variable?
          yield op
        when op.respond_to?(:replace_vars!)
          op.replace_vars!(&block) 
        else
          op
        end
      end
      self
    end
  end # Evaluatable
end; end # SPARQL::Algebra
