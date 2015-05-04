module SPARQL; module Algebra
  ##
  # Mixin for Algebra::Operator sub-classes that evaluate bindings to return a result
  #
  # @abstract
  module Evaluatable
    ##
    # Evaluates this operator using the given variable `bindings`.
    #
    # @param  [RDF::Query::Solution] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [RDF::Term]
    # @abstract
    def evaluate(bindings, options = {})
      args = operands.map { |operand| operand.evaluate(bindings, options.merge(depth: options[:depth].to_i + 1)) }
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
      @operands.map! do |op|
        case
        when op.is_a?(RDF::Query::Variable)
          yield op
        when op.respond_to?(:replace_vars!)
          op.replace_vars!(&block) 
        else
          op
        end
      end
      self
    end

    ##
    # Recursively re-map operators to replace aggregates with temporary variables returned from the block
    #
    # @yield agg
    # @yieldparam [SPARQL::Algebra::Aggregate] agg
    # @yieldreturn [RDF::Query::Variable]
    # @return [SPARQL::Algebra::Evaluatable, RDF::Query::Variable] self
    def replace_aggregate!(&block)
      @operands.map! do |op|
        case
        when op.aggregate?
          yield op
        when op.respond_to?(:replace_aggregate!)
          op.replace_aggregate!(&block) 
        else
          op
        end
      end
      self
    end
  end # Evaluatable
end; end # SPARQL::Algebra
