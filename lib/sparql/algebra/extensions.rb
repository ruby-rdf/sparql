require 'json'

##
# Extensions for Ruby's `NilClass` class.
class NilClass

  def evaluate(bindings, options = {})
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
  # Evaluates the array using the given variable `bindings`.
  #
  # In this case, the Array has two elements, the first of which is
  # an XSD datatype, and the second is the expression to be evaluated.
  # The result is cast as a literal of the appropriate type
  #
  # @param  [RDF::Query::Solution] bindings
  #   a query solution containing zero or more variable bindings
  # @param [Hash{Symbol => Object}] options ({})
  #   options passed from query
  # @return [RDF::Term]
  # @see {SPARQL::Algebra::Expression.evaluate}
  def evaluate(bindings, options = {})
    SPARQL::Algebra::Expression.extension(*self.map {|o| o.evaluate(bindings, options)})
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
  # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
  def execute(queryable, options = {})
    raise NotImplementedError, "SPARQL::Algebra '#{first}' operator not implemented"
  end

  ##
  # Returns `true` if any of the operands are variables, `false`
  # otherwise.
  #
  # @return [Boolean] `true` or `false`
  # @see    #constant?
  def variable?
    any?(&:variable?)
  end
  def constant?; !(variable?); end

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
end

##
# Extensions for Ruby's `Hash` class.
class Hash
  ##
  # Returns the SXP representation of this object, defaults to `self`.
  #
  # @return [String]
  def to_sxp_bin
    to_a.to_sxp_bin
  end
  def to_sxp; to_sxp_bin; end
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
  def evaluate(bindings, options = {})
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
  #     queryable.query(predicate: RDF::DOAP.developer)
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
  def query(pattern, options = {}, &block)
    raise TypeError, "#{self} is not queryable" if respond_to?(:queryable?) && !queryable?

    if pattern.is_a?(SPARQL::Algebra::Operator) && pattern.respond_to?(:execute)
      before_query(pattern) if respond_to?(:before_query)
      solutions = if method(:query_execute).arity == 1
        query_execute(pattern, &block)
      else
        query_execute(pattern, options, &block)
      end
      after_query(pattern) if respond_to?(:after_query)

      if !pattern.respond_to?(:query_yeilds_solutions?) || pattern.query_yields_solutions?
        # Just return solutions
        solutions
      else
        # Return an enumerator
        enum_for(:query, pattern, options)
      end
    else
      query_without_sparql(pattern, options, &block)
    end
  end
  
end

class RDF::Statement
  # Transform Statement Pattern into an SXP
  # @return [Array]
  def to_sxp_bin
    if has_graph?
      [:quad, subject, predicate, object, graph_name]
    else
      [:triple, subject, predicate, object]
    end
  end
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
  # Return the non-destinguished variables contained within patterns
  # @return [Array<RDF::Query::Variable>]
  def ndvars
    patterns.map(&:ndvars).flatten
  end

  ##
  # Return the variables contained within patterns
  # @return [Array<RDF::Query::Variable>]
  def vars
    patterns.map(&:vars).flatten
  end
end

class RDF::Query::Pattern
  # Transform Query Pattern into an SXP
  # @return [Array]
  def to_sxp_bin
    if has_graph?
      [:quad, subject, predicate, object, graph_name]
    else
      [:triple, subject, predicate, object]
    end
  end

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
  def evaluate(bindings, options = {})
    raise TypeError if bindings.respond_to?(:bound?) && !bindings.bound?(self)
    bindings[name.to_sym]
  end

  def to_s
    prefix = distinguished? || name.to_s[0,1] == '.' ? '?' : "??"
    unbound? ? "#{prefix}#{name}" : "#{prefix}#{name}=#{value}"
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
