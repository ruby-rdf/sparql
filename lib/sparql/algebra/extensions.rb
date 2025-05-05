require 'json'

##
# Extensions for Ruby's `NilClass` class.
class NilClass

  def evaluate(bindings, **options)
    self
  end

end

##
# Extensions for Ruby's `Object` class.
class Object
  ##
  # Returns the SXP binary representation of this object, defaults to `self`.
  #
  # @return [String]
  def to_sxp_bin
    self
  end
  
  ##
  # Make sure the object is in SXP form and transform it to a string form
  # @return String
  def to_sse
    SXP::Generator.string(self.to_sxp_bin)
  end

  ##
  # A duplicate of this object.
  #
  # @return [Object] a copy of `self`
  # @see SPARQL::Algebra::Expression#optimize
  def optimize(**options)
    self.deep_dup
  end

  ##
  # Default for deep_dup is shallow dup
  # @return [Object]
  def deep_dup
    dup
  end

  ##
  #
  # Returns a partial SPARQL grammar for this term.
  #
  # @return [String]
  def to_sparql(**options)
    to_sxp(**options)
  end
end

##
# Extensions for Ruby's `Array` class.
class Array
  ##
  # Returns the SXP representation of this object, defaults to `self`.
  #
  # @return [String]
  def to_sxp_bin
    map {|x| x.to_sxp_bin}
  end

  ##
  #
  # Returns a partial SPARQL grammar for this array.
  #
  # @param [String] delimiter (" ")
  #   If the first element is an IRI, treat it as an extension function
  # @return [String]
  def to_sparql(delimiter: " ",  **options)
    map {|e| e.to_sparql(**options)}.join(delimiter)
  end

  ##
  # If `#execute` is invoked, it implies that a non-implemented Algebra operator
  # is being invoked
  #
  # @param  [RDF::Queryable] queryable
  #   the graph or repository to query
  # @param  [Hash{Symbol => Object}] options
  # @raise [NotImplementedError]
  #   If an attempt is made to perform an unsupported operation
  # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
  def execute(queryable, **options)
    raise NotImplementedError, "SPARQL::Algebra '#{first}' operator not implemented"
  end

  ##
  # Return an optimized version of this array.
  #
  # @return [Array] a copy of `self`
  # @see SPARQL::Algebra::Expression#optimize
  def optimize(**options)
    self.map do |op|
      op.optimize(**options) if op.respond_to?(:optimize)
    end
  end

  ##
  # Binds the pattern to a solution, making it no longer variable if all variables are resolved to bound variables
  #
  # @param [RDF::Query::Solution] solution
  # @return [self]
  def bind(solution)
    map! do |op|
      op.respond_to?(:bind) ? op.bind(solution) : op
    end
    self
  end

  ##
  # Returns `true` if any of the operands are variables, `false`
  # otherwise.
  #
  # @return [Boolean] `true` or `false`
  # @see    #constant?
  def variable?
    any? {|op| op.respond_to?(:variable?) && op.variable?}
  end
  def constant?; !(variable?); end

  ##
  # The variables used in this array.
  #
  # @return [Hash{Symbol => RDF::Query::Variable}]
  def variables
    self.inject({}) {|hash, o| o.respond_to?(:variables) ? hash.merge(o.variables) : hash}
  end

  ##
  # Does this contain any nodes?
  #
  # @return [Boolean]
  def node?
    any?(&:node?)
  end
  def evaluatable?; true; end
  def executable?; false; end
  def aggregate?; false; end

  ##
  # Replace operators which are variables with the result of the block
  # descending into operators which are also evaluatable
  #
  # @yield var
  # @yieldparam [RDF::Query::Variable] var
  # @yieldreturn [RDF::Query::Variable, SPARQL::Algebra::Evaluatable]
  # @return [SPARQL::Algebra::Evaluatable] self
  def replace_vars!(&block)
    map! do |op|
      case
      when op.respond_to?(:variable?) && op.variable?
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
    map! do |op|
      case
      when op.respond_to?(:aggregate?) && op.aggregate?
        yield op
      when op.respond_to?(:replace_aggregate!)
        op.replace_aggregate!(&block) 
      else
        op
      end
    end
    self
  end

  ##
  # Return the non-destinguished variables contained within this Array
  # @return [Array<RDF::Query::Variable>]
  def ndvars
    vars.reject(&:distinguished?)
  end

  ##
  # Return the variables contained within this Array
  # @return [Array<RDF::Query::Variable>]
  def vars
    select {|o| o.respond_to?(:vars)}.map(&:vars).flatten.compact
  end

  ##
  # Is this value composed only of valid components?
  #
  # @return [Boolean] `true` or `false`
  def valid?
    all? {|e| e.respond_to?(:valid?) ? e.valid? : true}
  end

  ##
  # Validate all components.
  # @return [Array] `self`
  # @raise  [ArgumentError] if the value is invalid
  def validate!
    each {|e| e.validate! if e.respond_to?(:validate!)}
    self
  end

  ##
  # Deep duplicate
  def deep_dup
    map(&:deep_dup)
  end
end

##
# Extensions for Ruby's `Hash` class.
class Hash
  ##
  # A duplicate of this hash.
  #
  # @return [Hash] a copy of `self`
  # @see SPARQL::Algebra::Expression#optimize
  def optimize(**options)
    self.deep_dup
  end

  ##
  # Deep duplicate
  def deep_dup
    inject({}) {|memo, (k, v)| memo.merge(k => v.deep_dup)}
  end
end

##
# Extensions for `RDF::Term`.
module RDF::Term
  include SPARQL::Algebra::Expression
  
  # @param  [RDF::Query::Solution] bindings
  #   a query solution containing zero or more variable bindings
  # @param [Hash{Symbol => Object}] options ({})
  #   options passed from query
  # @return [RDF::Term]
  def evaluate(bindings, **options)
    self
  end

  def aggregate?; false; end

  ##
  # Return the non-destinguished variables contained within this operator
  # @return [Array<RDF::Query::Variable>]
  def ndvars
    vars.reject(&:distinguished?)
  end

  ##
  # Return the variables contained within this operator
  # @return [Array<RDF::Query::Variable>]
  def vars
    variable? ? [self] : []
  end

  ##
  # A duplicate of this term.
  #
  # @return [RDF::Term] a copy of `self`
  # @see SPARQL::Algebra::Expression#optimize
  def optimize(**options)
    optimized = self.deep_dup
    #optimized.lexical = nil if optimized.respond_to?(:lexical=)
    #optimized
  end

  ##
  #
  # Returns a partial SPARQL grammar for this term.
  #
  # @return [String]
  def to_sparql(**options)
    to_sxp(**options)
  end
end # RDF::Term

# Override RDF::Queryable to execute against SPARQL::Algebra::Query elements as well as RDF::Query and RDF::Pattern
module RDF::Queryable
  alias_method :query_without_sparql, :query
  ##
  # Queries `self` for RDF statements matching the given `pattern`.
  #
  # Monkey patch to RDF::Queryable#query to execute a {SPARQL::Algebra::Operator}
  # in addition to an {RDF::Query} object.
  #
  # @example
  #     queryable.query([nil, RDF::DOAP.developer, nil])
  #     queryable.query({predicate: RDF::DOAP.developer})
  #
  #     op = SPARQL::Algebra::Expression.parse(%q((bgp (triple ?a doap:developer ?b))))
  #     queryable.query(op)
  #
  # @param  [RDF::Query, RDF::Statement, Array(RDF::Term), Hash, SPARQL::Operator] pattern
  # @yield  [statement]
  #   each matching statement
  # @yieldparam  [RDF::Statement] statement
  # @yieldreturn [void] ignored
  # @return [Enumerator]
  # @see    RDF::Queryable#query_pattern
  def query(pattern, **options, &block)
    raise TypeError, "#{self} is not queryable" if respond_to?(:queryable?) && !queryable?

    if pattern.is_a?(SPARQL::Algebra::Operator) && pattern.respond_to?(:execute)
      before_query(pattern) if respond_to?(:before_query)
      solutions = if method(:query_execute).arity == 1
        query_execute(pattern, &block)
      else
        query_execute(pattern, **options, &block)
      end
      after_query(pattern) if respond_to?(:after_query)

      if !pattern.respond_to?(:query_yeilds_solutions?) || pattern.query_yields_solutions?
        # Just return solutions
        solutions
      else
        # Return an enumerator
        enum_for(:query, pattern, **options)
      end
    else
      query_without_sparql(pattern, **options, &block)
    end
  end

  ##
  #
  # Returns a partial SPARQL grammar for this term.
  #
  # @return [String]
  def to_sparql(**options)
    raise NotImplementedError, "SPARQL::Algebra '#{first}' operator not implemented"
  end
end

class RDF::Statement
  # Transform Statement Pattern into an SXP
  # @return [Array]
  def to_sxp_bin
    [ (has_graph? ? :quad : (tripleTerm? ? :qtriple : :triple)),
      (:inferred if inferred?),
      subject,
      predicate,
      object,
      graph_name
    ].compact.map(&:to_sxp_bin)
  end

  ##
  # Returns an S-Expression (SXP) representation
  #
  # @param [Hash{Symbol => RDF::URI}] prefixes (nil)
  # @param [RDF::URI] base_uri (nil)
  # @return [String]
  def to_sxp(prefixes: nil, base_uri: nil)
    to_sxp_bin.to_sxp(prefixes: prefixes, base_uri: base_uri)
  end

  ##
  #
  # Returns a partial SPARQL grammar for this term.
  #
  # @return [String]
  def to_sparql(**options)
    str = to_triple.map {|term| term.to_sparql(**options)}.join(" ")
    tripleTerm? ? ('<<(' + str + ')>>') : str
  end

  ##
  # A duplicate of this Statement.
  #
  # @return [RDF::Statement] a copy of `self`
  # @see SPARQL::Algebra::Expression#optimize
  def optimize(**options)
    self.dup
  end

  def executable?; false; end
end

class RDF::Query
  # Equivalence for Queries:
  #   Same Patterns
  #   Same Context
  # @return [Boolean]
  def ==(other)
    # FIXME: this should be graph_name == other.graph_name
    other.is_a?(RDF::Query) && patterns == other.patterns && graph_name == graph_name
  end
      
  ##
  # Don't do any more rewriting
  # @return [SPARQL::Algebra::Expression] `self`
  def rewrite(&block)
    self
  end

  # Transform Query into an Array form of an SSE
  #
  # If Query has the `as_container` option set, serialize as Quads
  # Otherwise, If Query is named, serialize as a GroupGraphPattern.
  # Otherise, serialize as a BGP
  #
  # @return [Array]
  def to_sxp_bin
    if options[:as_container]
      [:graph, graph_name] + [patterns.map(&:to_sxp_bin)]
    else
      res = [:bgp] + patterns.map(&:to_sxp_bin)
      (graph_name ? [:graph, graph_name, res] : res)
    end
  end

  # Two queries can be merged if they share the same graph_name
  #
  # @param [RDF::Query] other
  # @return [Boolean]
  def mergable?(other)
    other.is_a?(RDF::Query) && self.graph_name == other.graph_name
  end

  # Two queries are merged by 
  #
  # @param [RDF::Query] other
  # @return [RDF::Query]
  def merge(other)
    raise ArgumentError, "Can't merge with #{other.class}" unless mergable?(other)
    self.dup.tap {|q| q.instance_variable_set(:@patterns, q.patterns + other.patterns)}
  end

  ##
  #
  # Returns a partial SPARQL grammar for this query.
  #
  # @param [Boolean] top_level (true)
  #   Treat this as a top-level, generating SELECT ... WHERE {}
  # @param [Array<Operator>] filter_ops ([])
  #   Filter Operations
  # @return [String]
  def to_sparql(top_level: true, filter_ops: [], **options)
    str = @patterns.map do |e|
      e.to_sparql(top_level: false, **options) + " . \n"
    end.join("")
    str = "GRAPH #{graph_name.to_sparql(**options)} {\n#{str}\n}\n" if graph_name
    if top_level
      SPARQL::Algebra::Operator.to_sparql(str, filter_ops: filter_ops, **options)
    else
      # Filters
      filter_ops.each do |op|
        str << "\nFILTER (#{op.to_sparql(**options)}) ."
      end

      # Extensons
      extensions = options.fetch(:extensions, [])
      extensions.each do |as, expression|
        v = expression.to_sparql(**options)
        pp = RDF::Query::Variable.new(as).to_sparql(**options)
        str << "\nBIND (" << v << " AS " << pp << ") ."
      end
      str = "{#{str}}" unless filter_ops.empty? && extensions.empty?
      str
    end
  end

  ##
  # Binds the pattern to a solution, making it no longer variable if all variables are resolved to bound variables
  #
  # @param [RDF::Query::Solution] solution
  # @return [self]
  def bind(solution)
    patterns.each {|p| p.bind(solution)}
    self
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
    true
  end

  ##
  # Return the non-destinguished variables contained within patterns and graph name
  # @return [Array<RDF::Query::Variable>]
  def ndvars
    vars.reject(&:distinguished?)
  end

  ##
  # Return the variables contained within patterns and graph name
  # @return [Array<RDF::Query::Variable>]
  def vars
    variables.values
  end

  alias_method :optimize_without_expression!, :optimize!
  ##
  # Optimize the query, removing lexical shortcuts in URIs
  #
  # @return [self]
  # @see SPARQL::Algebra::Expression#optimize!
  def optimize!(**options)
    @patterns = @patterns.map do |pattern|
      components = pattern.to_quad.map do |term|
        #if term.respond_to?(:lexical=)
        #  term.dup.instance_eval {@lexical = nil; self}
        #else
          term
        #end
      end
      RDF::Query::Pattern.from(components, **pattern.options)
    end
    self.optimize_without_expression!(**options)
  end

  ##
  # Returns `true` as this is executable.
  #
  # @return [Boolean] `true`
  def executable?; true; end
end

class RDF::Query::Pattern
  ##
  # Return the non-destinguished variables contained within this pattern
  # @return [Array<RDF::Query::Variable>]
  def ndvars
    vars.reject(&:distinguished?)
  end

  ##
  # Return the variables contained within this pattern
  # @return [Array<RDF::Query::Variable>]
  def vars
    variables.values
  end

  ##
  # Returns `true` as this is executable.
  #
  # @return [Boolean] `true`
  def executable?; true; end

  ##
  # Returns an S-Expression (SXP) representation
  #
  # @param [Hash{Symbol => RDF::URI}] prefixes (nil)
  # @param [RDF::URI] base_uri (nil)
  # @return [String]
  def to_sxp(prefixes: nil, base_uri: nil)
    to_sxp_bin.to_sxp(prefixes: prefixes, base_uri: base_uri)
  end
end

##
# Extensions for `RDF::Query::Variable`.
class RDF::Query::Variable
  include SPARQL::Algebra::Expression

  ##
  # Returns the value of this variable in the given `bindings`.
  #
  # @param  [RDF::Query::Solution] bindings
  #   a query solution containing zero or more variable bindings
  # @param [Hash{Symbol => Object}] options ({})
  #   options passed from query
  # @return [RDF::Term] the value of this variable
  # @raise [TypeError] if the variable is not bound
  def evaluate(bindings, **options)
    raise TypeError if bindings.respond_to?(:bound?) && !bindings.bound?(self)
    bindings[name.to_sym]
  end

  ##
  # Return self
  #
  # @return [RDF::Query::Variable] a copy of `self`
  # @see SPARQL::Algebra::Expression#optimize
  def optimize(**options)
    self
  end

  ##
  #
  # Returns a partial SPARQL grammar for this term.
  #
  # The Non-distinguished form (`??xxx`) is not part of the grammar, so replace with a blank-node
  #
  # @return [String]
  def to_sparql(**options)
    self.distinguished? ? super : "_:_nd#{self.name}"
  end
end # RDF::Query::Variable

##
# Extensions for `RDF::Query::Solutions`.
class RDF::Query::Solutions
  alias_method :filter_without_expression, :filter

  ##
  # Filters this solution sequence by the given `criteria`.
  #
  # @param  [SPARQL::Algebra::Expression] expression
  # @yield  [solution]
  #   each solution
  # @yieldparam  [RDF::Query::Solution] solution
  # @yieldreturn [Boolean]
  # @return [void] `self`
  def filter(expression = {}, &block)
    case expression
      when SPARQL::Algebra::Expression
        filter_without_expression do |solution|
          expression.evaluate(solution).true?
        end
        filter_without_expression(&block) if block_given?
        self
      else filter_without_expression(expression, &block)
    end
  end
  alias_method :filter!, :filter
end # RDF::Query::Solutions

##
# Extensions for `RDF::Query::Solution`.
class RDF::Query::Solution
  ##
  # Returns the SXP representation of this object, defaults to `self`.
  #
  # @return [String]
  def to_sxp_bin
    to_a.to_sxp_bin
  end

  # Transform Solution into an SXP
  #
  # @param [Hash{Symbol => RDF::URI}] prefixes (nil)
  # @param [RDF::URI] base_uri (nil)
  # @return [String]
  def to_sxp(prefixes: nil, base_uri: nil)
    to_sxp_bin.to_sxp(prefixes: prefixes, base_uri: base_uri)
  end
end # RDF::Query::Solution
