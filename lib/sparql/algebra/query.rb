module SPARQL; module Algebra
  ##
  # A SPARQL algebra query, may be duck-typed as RDF::Query.
  #
  # Mixin with SPARQL::Algebra::Operator to provide query-like operations on graphs and filters
  #
  # @abstract
  module Query
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
    # The variables used in this query.
    #
    # @return [Hash{Symbol => RDF::Query::Variable}]
    def variables
      operands.inject({}) {|hash, o| o.executable? ? hash.merge!(o.variables) : hash}
    end

    ##
    # The solution sequence for this query.
    #
    # @return [RDF::Query::Solutions]
    attr_reader :solutions

    ##
    # Executes this query on the given `queryable` graph or repository.
    #
    # @param  [RDF::Queryable] queryable
    #   the graph or repository to query
    # @param  [Hash{Symbol => Object}] options
    #   any additional keyword options
    # @option options [Boolean] debug
    #   Query execution debugging
    # @return [RDF::Query::Solutions]
    #   the resulting solution sequence
    # @raise [TypeError]
    #   TypeError raised if any operands are invalid
    # @raise [NotImplementedError]
    #   If an attempt is made to perform an unsupported operation
    # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
    def execute(queryable, options = {})
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

    ##
    # Returns `true` if this query did not match when last executed.
    #
    # When the solution sequence is empty, this method can be used to
    # determine whether the query failed to match or not.
    #
    # @return [Boolean]
    # @see    #matched?
    def failed?
      solutions.empty?
    end

    ##
    # Returns `true` if this query matched when last executed.
    #
    # When the solution sequence is empty, this method can be used to
    # determine whether the query matched successfully or not.
    #
    # @return [Boolean]
    # @see    #failed?
    def matched?
      !failed?
    end

    ##
    # Enumerates over each matching query solution.
    #
    # @yield  [solution]
    # @yieldparam [RDF::Query::Solution] solution
    # @return [Enumerator]
    def each_solution(&block)
      solutions.each(&block)
    end
    alias_method :each, :each_solution
  end # Query
end; end # SPARQL::Algebra
