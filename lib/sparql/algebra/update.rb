module SPARQL; module Algebra
  ##
  # A SPARQL algebra Update can make modifications to it's dataset
  #
  # Mixin with SPARQL::Algebra::Operator to provide update-like operations on graphs
  #
  # @abstract
  module Update
    ##
    # Prepends an operator.
    #
    # @param  [RDF::Query] query
    #   a query
    # @return [void] self
    def unshift(query)
      @operands.unshift(query)
      self
    end
    
    ##
    # The variables used in this update.
    #
    # @return [Hash{Symbol => RDF::Query::Variable}]
    def variables
      operands.inject({}) {|hash, o| o.executable? ? hash.merge!(o.variables) : hash}
    end

    ##
    # Executes this upate on the given `queryable` graph or repository.
    #
    # @param  [RDF::Writable] queryable
    #   the graph or repository to write
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @option options [Boolean] debug
    #   Query execution debugging
    # @return [RDF::Writable]
    #   Returns the dataset.
    # @raise [NotImplementedError]
    #   If an attempt is made to perform an unsupported operation
    # @see    http://www.w3.org/TR/sparql11-update/
    def execute(queryable, options = {}, &block)
      raise NotImplementedError, "#{self.class}#execute(#{queryable})"
    end

    # Add context to sub-items, unless they already have a context
    # @param [RDF::URI, RDF::Query::Variable] value
    # @return [RDF::URI, RDF::Query::Variable]
    def context=(value)
      operands.each do |operand|
        operand.context = value if operand.respond_to?(:context) && operand.context != false
      end
      value
    end
  end # Query
end; end # SPARQL::Algebra
