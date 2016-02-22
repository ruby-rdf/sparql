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
    # The solution sequence for this query. This is only set
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
    # @option options [RDF::Term, RDF::Query::Variable] :graph_name
    # @yield  [solution]
    #   each matching solution, statement or boolean
    # @yieldparam  [RDF::Statement, RDF::Query::Solution, Boolean] solution
    # @yieldreturn [void] ignored
    # @return [RDF::Graph, Boolean, RDF::Query::Solutions::Enumerator]
    #   Note, results may be used with {SPARQL.serialize_results} to obtain appropriate output encoding.
    # @raise [NotImplementedError]
    #   If an attempt is made to perform an unsupported operation
    # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    def execute(queryable, options = {}, &block)
      raise NotImplementedError, "#{self.class}#execute(#{queryable})"
    end

    # Add graph_name to sub-items, unless they already have a graph_name
    # @param [RDF::URI, RDF::Query::Variable] value
    # @return [RDF::URI, RDF::Query::Variable]
    def graph_name=(value)
      operands.each do |operand|
        operand.graph_name = value if operand.respond_to?(:graph_name) && operand.graph_name != false
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

    # Determine if this is an empty query, having no operands
    def empty?
      self.operands.empty?
    end

    # Query results in a boolean result (e.g., ASK)
    # @return [Boolean]
    def query_yields_boolean?
      false
    end

    # Query results statements (e.g., CONSTRUCT, DESCRIBE, CREATE)
    # @return [Boolean]
    def query_yields_statements?
      false
    end

    # Query results solutions (e.g., SELECT)
    # @return [Boolean]
    def query_yields_solutions?
      !(query_yields_boolean? || query_yields_statements?)
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
  end # Query
end; end # SPARQL::Algebra
