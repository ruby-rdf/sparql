module SPARQL; module Algebra
  ##
  # A SPARQL operator.
  #
  # @abstract
  class Operator
    include Expression

    # Unary operators
    autoload :Not,                'sparql/algebra/operator/not'
    autoload :Plus,               'sparql/algebra/operator/plus'
    autoload :Minus,              'sparql/algebra/operator/minus'
    autoload :Bound,              'sparql/algebra/operator/bound'
    autoload :IsBlank,            'sparql/algebra/operator/is_blank'
    autoload :IsIRI,              'sparql/algebra/operator/is_iri'
    autoload :IsURI,              'sparql/algebra/operator/is_iri'
    autoload :IsLiteral,          'sparql/algebra/operator/is_literal'
    autoload :Str,                'sparql/algebra/operator/str'
    autoload :Lang,               'sparql/algebra/operator/lang'
    autoload :Datatype,           'sparql/algebra/operator/datatype'

    # Binary operators
    autoload :Or,                 'sparql/algebra/operator/or'
    autoload :And,                'sparql/algebra/operator/and'
    autoload :Compare,            'sparql/algebra/operator/compare'
    autoload :Equal,              'sparql/algebra/operator/equal'
    autoload :NotEqual,           'sparql/algebra/operator/not_equal'
    autoload :LessThan,           'sparql/algebra/operator/less_than'
    autoload :GreaterThan,        'sparql/algebra/operator/greater_than'
    autoload :LessThanOrEqual,    'sparql/algebra/operator/less_than_or_equal'
    autoload :GreaterThanOrEqual, 'sparql/algebra/operator/greater_than_or_equal'
    autoload :Multiply,           'sparql/algebra/operator/multiply'
    autoload :Divide,             'sparql/algebra/operator/divide'
    autoload :Add,                'sparql/algebra/operator/add'
    autoload :Subtract,           'sparql/algebra/operator/subtract'
    autoload :SameTerm,           'sparql/algebra/operator/same_term'
    autoload :LangMatches,        'sparql/algebra/operator/lang_matches'
    autoload :Regex,              'sparql/algebra/operator/regex'

    # Miscellaneous
    autoload :Asc,                'sparql/algebra/operator/asc'
    autoload :Desc,               'sparql/algebra/operator/desc'
    autoload :Exprlist,           'sparql/algebra/operator/exprlist'

    # Query operators
    autoload :Ask,                'sparql/algebra/operator/ask'
    autoload :Base,               'sparql/algebra/operator/base'
    autoload :BGP,                'sparql/algebra/operator/bgp'
    autoload :Construct,          'sparql/algebra/operator/construct'
    autoload :Dataset,            'sparql/algebra/operator/dataset'
    autoload :Describe,           'sparql/algebra/operator/describe'
    autoload :Distinct,           'sparql/algebra/operator/distinct'
    autoload :Filter,             'sparql/algebra/operator/filter'
    autoload :Graph,              'sparql/algebra/operator/graph'
    autoload :Join,               'sparql/algebra/operator/join'
    autoload :LeftJoin,           'sparql/algebra/operator/left_join'
    autoload :Order,              'sparql/algebra/operator/order'
    autoload :Prefix,             'sparql/algebra/operator/prefix'
    autoload :Project,            'sparql/algebra/operator/project'
    autoload :Reduced,            'sparql/algebra/operator/reduced'
    autoload :Slice,              'sparql/algebra/operator/slice'
    autoload :Union,              'sparql/algebra/operator/union'

    ##
    # Returns an operator class for the given operator `name`.
    #
    # @param  [Symbol, #to_s]  name
    # @param  [Integer] arity
    # @return [Class] an operator class, or `nil` if an operator was not found
    def self.for(name, arity = nil)
      # TODO: refactor this to dynamically introspect loaded operator classes.
      case (name.to_s.downcase.to_sym rescue nil)
        when :<=>         then Compare # non-standard
        when :'='         then Equal
        when :'!='        then NotEqual
        when :<           then LessThan
        when :>           then GreaterThan
        when :<=          then LessThanOrEqual
        when :>=          then GreaterThanOrEqual
        when :*           then Multiply
        when :'/'         then Divide
        when :+           then arity.eql?(1) ? Plus  : Add
        when :-           then arity.eql?(1) ? Minus : Subtract
        when :not, :'!'   then Not
        when :plus        then Plus
        when :minus       then Minus
        when :bound       then Bound
        when :isblank     then IsBlank
        when :isiri       then IsIRI
        when :isuri       then IsIRI # alias
        when :isliteral   then IsLiteral
        when :str         then Str
        when :lang        then Lang
        when :datatype    then Datatype
        when :or, :'||'   then Or
        when :and, :'&&'  then And
        when :multiply    then Multiply
        when :divide      then Divide
        when :add         then Add
        when :subtract    then Subtract
        when :sameterm    then SameTerm
        when :langmatches then LangMatches
        when :regex       then Regex
        
        # Miscellaneous
        when :asc         then Asc
        when :desc        then Desc
        when :exprlist    then Exprlist

        # Datasets
        when :dataset     then Dataset
        
        # Query forms
        when :ask         then Ask
        when :base        then Base
        when :bgp         then BGP
        when :construct   then Construct
        when :describe    then Describe
        when :distinct    then Distinct
        when :filter      then Filter
        when :graph       then Graph
        when :join        then Join
        when :leftjoin    then LeftJoin
        when :order       then Order
        when :prefix      then Prefix
        when :project     then Project
        when :reduced     then Reduced
        when :slice       then Slice
        when :triple      then RDF::Query::Pattern
        when :union       then Union
        else nil # not found
      end
    end

    ##
    # @param  [Array<RDF::Term>] operands
    # @return [RDF::Term]
    # @see    Operator#evaluate
    def self.evaluate(*operands)
      self.new(*operands).evaluate(RDF::Query::Solution.new)
    end

    ##
    # Returns the arity of this operator class.
    #
    # @example
    #   Operator.arity           #=> -1
    #   Operator::Nullary.arity  #=> 0
    #   Operator::Unary.arity    #=> 1
    #   Operator::Binary.arity   #=> 2
    #   Operator::Ternary.arity  #=> 3
    #
    # @return [Integer] an integer in the range `(-1..3)`
    def self.arity
      self.const_get(:ARITY)
    end

    ARITY = -1 # variable arity

    ##
    # Initializes a new operator instance.
    #
    # @param  [Array<RDF::Term>] operands
    # @param  [Hash{Symbol => Object}] options
    #   any additional options
    # @option options [Boolean] :memoize (false)
    #   whether to memoize results for particular operands
    # @raise  [TypeError] if any operand is invalid
    def initialize(*operands)
      @options  = operands.last.is_a?(Hash) ? operands.pop.dup : {}
      @operands = operands.map! do |operand|
        case operand
          when Operator, Variable, RDF::Term, RDF::Query, RDF::Query::Pattern, Array, Symbol
            operand
          when TrueClass, FalseClass, Numeric, String, DateTime, Date, Time
            RDF::Literal(operand)
          else raise TypeError, "invalid SPARQL::Algebra::Operator operand: #{operand.inspect}"
        end
      end
    end

    ##
    # Base URI used for reading data sources with relative URIs
    #
    # @return [RDF::URI]
    def base_uri
      Operator.base_uri
    end
    
    ##
    # Base URI used for reading data sources with relative URIs
    #
    # @return [RDF::URI]
    def self.base_uri
      @base_uri
    end
    
    ##
    # Set Base URI associated with SPARQL document, typically done
    # when reading SPARQL from a URI
    #
    # @param [RDF::URI] base
    # @return [RDF::URI]
    def self.base_uri=(uri)
      @base_uri = RDF::URI(uri)
    end
    
    ##
    # Prefixes useful for future serialization
    #
    # @return [Hash{Symbol => RDF::URI}]
    #   Prefix definitions
    def prefixes
      Operator.prefixes
    end
    
    ##
    # Prefixes useful for future serialization
    #
    # @return [Hash{Symbol => RDF::URI}]
    #   Prefix definitions
    def self.prefixes
      @prefixes
    end
    
    ##
    # Prefixes useful for future serialization
    #
    # @param [Hash{Symbol => RDF::URI}] hash
    #   Prefix definitions
    # @return [Hash{Symbol => RDF::URI}]
    def self.prefixes=(hash)
      @prefixes = hash
    end
    
    ##
    # Any additional options for this operator.
    #
    # @return [Hash]
    attr_reader :options

    ##
    # The operands to this operator.
    #
    # @return [Array]
    attr_reader :operands

    ##
    # Returns the operand at the given `index`.
    #
    # @param  [Integer] index
    #   an operand index in the range `(0...(operands.count))`
    # @return [RDF::Term]
    def operand(index = 0)
      operands[index]
    end

    ##
    # Returns `true` if any of the operands are variables, `false`
    # otherwise.
    #
    # @return [Boolean] `true` or `false`
    # @see    #constant?
    def variable?
      operands.any? do |operand|
        operand.is_a?(Variable) ||
          (operand.respond_to?(:variable?) && operand.variable?)
      end
    end

    ##
    # Returns `true` if this is evaluatable (i.e., returns values for a binding), `false`
    # otherwise.
    #
    # @return [Boolean] `true` or `false`
    def evaluatable?
      respond_to?(:evaluate)
    end

    ##
    # Returns `true` if this is executable (i.e., contains a graph patterns), `false`
    # otherwise.
    #
    # @return [Boolean] `true` or `false`
    def executable?
      respond_to?(:execute)
    end

    ##
    # Returns `true` if none of the operands are variables, `false`
    # otherwise.
    #
    # @return [Boolean] `true` or `false`
    # @see    #variable?
    def constant?
      !(variable?)
    end

    ##
    # Returns an optimized version of this expression.
    #
    # For constant expressions containing no variables, returns the result
    # of evaluating the expression with empty bindings; otherwise returns
    # `self`.
    #
    # Optimization is not possible if the expression raises an exception,
    # such as a `TypeError` or `ZeroDivisionError`, which must be conserved
    # at runtime.
    #
    # @return [SPARQL::Algebra::Expression]
    def optimize
      if constant?
        # Note that if evaluation results in a `TypeError` or other error,
        # we must return `self` so that the error is conserved at runtime:
        evaluate rescue self
      else
        super # returns `self`
      end
    end

    ##
    # Returns the SPARQL S-Expression (SSE) representation of this operator.
    #
    # @return [Array]
    # @see    http://openjena.org/wiki/SSE
    def to_sse
      operator = [self.class.const_get(:NAME)].flatten.first
      [operator, *(operands || []).map(&:to_sse)]
    end

    ##
    # Returns an S-Expression (SXP) representation of this operator
    #
    # @return [String]
    def to_sxp
      begin
        require 'sxp' # @see http://rubygems.org/gems/sxp
      rescue LoadError
        abort "SPARQL::Algebra::Operator#to_sxp requires the SXP gem (hint: `gem install sxp')."
      end
      require 'sparql/algebra/sxp_extensions'
      
      to_sse.to_sxp
    end

    ##
    # Returns a developer-friendly representation of this operator.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, operands.map(&:inspect).join(', '))
    end

    ##
    # @param  [Statement] other
    # @return [Boolean]
    def eql?(other)
      other.class == self.class && other.operands == self.operands
    end
    alias_method :==, :eql?
  protected

    ##
    # Returns the effective boolean value (EBV) of the given `literal`.
    #
    # @param  [RDF::Literal] literal
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @raise  [TypeError] if the literal could not be coerced to an `RDF::Literal::Boolean`
    # @see    http://www.w3.org/TR/rdf-sparql-query/#ebv
    def boolean(literal)
      case literal
        when FalseClass then RDF::Literal::FALSE
        when TrueClass  then RDF::Literal::TRUE
        # If the argument is a typed literal with a datatype of
        # `xsd:boolean`, the EBV is the value of that argument.
        # However, the EBV of any literal whose type is `xsd:boolean` is
        # false if the lexical form is not valid for that datatype.
        when RDF::Literal::Boolean
          RDF::Literal(literal.valid? && literal.true?)
        # If the argument is a numeric type or a typed literal with a
        # datatype derived from a numeric type, the EBV is false if the
        # operand value is NaN or is numerically equal to zero; otherwise
        # the EBV is true.
        # However, the EBV of any literal whose type is numeric is
        # false if the lexical form is not valid for that datatype.
        when RDF::Literal::Numeric
          RDF::Literal(literal.valid? && !(literal.zero?) && !(literal.respond_to?(:nan?) && literal.nan?))
        # If the argument is a plain literal or a typed literal with a
        # datatype of `xsd:string`, the EBV is false if the operand value
        # has zero length; otherwise the EBV is true.
        else case
          when literal.is_a?(RDF::Literal) && (literal.plain? || literal.datatype.eql?(RDF::XSD.string))
            RDF::Literal(!(literal.value.empty?))
        # All other arguments, including unbound arguments, produce a type error.
          else raise TypeError, "could not coerce #{literal.inspect} to an RDF::Literal::Boolean"
        end
      end
    end

  private

    @@subclasses = [] # @private

    ##
    # @private
    # @return [void]
    def self.inherited(child)
      @@subclasses << child unless child.superclass.equal?(Operator) # grandchildren only
      super
    end

    ##
    # A SPARQL nullary operator.
    #
    # Operators of this kind take no operands.
    #
    # @abstract
    class Nullary < Operator
      ARITY = 0

      ##
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(options = {})
        super
      end
    end # Nullary

    ##
    # A SPARQL unary operator.
    #
    # Operators of this kind take one operand.
    #
    # @abstract
    class Unary < Operator
      ARITY = 1

      ##
      # @param  [RDF::Term] arg
      #   the operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg, options = {})
        super
      end
    end # Unary

    ##
    # A SPARQL binary operator.
    #
    # Operators of this kind take two operands.
    #
    # @abstract
    class Binary < Operator
      ARITY = 2

      ##
      # @param  [RDF::Term] arg1
      #   the first operand
      # @param  [RDF::Term] arg2
      #   the second operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg1, arg2, options = {})
        super
      end
    end # Binary

    ##
    # A SPARQL ternary operator.
    #
    # Operators of this kind take three operands.
    #
    # @abstract
    class Ternary < Operator
      ARITY = 3

      ##
      # @param  [RDF::Term] arg1
      #   the first operand
      # @param  [RDF::Term] arg2
      #   the second operand
      # @param  [RDF::Term] arg3
      #   the third operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg1, arg2, arg3, options = {})
        super
      end
    end # Ternary
  end # Operator
end; end # SPARQL::Algebra
