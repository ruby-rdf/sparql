module SPARQL; module Algebra
  ##
  # A SPARQL operator.
  #
  # @abstract
  class Operator
    include Expression

    # Nullary operatos
    autoload :Now,                'sparql/algebra/operator/now'
    autoload :Rand,               'sparql/algebra/operator/rand'
    autoload :StrUUID,            'sparql/algebra/operator/struuid'
    autoload :UUID,               'sparql/algebra/operator/uuid'

    # Unary operators
    autoload :Abs,                'sparql/algebra/operator/abs'
    autoload :Avg,                'sparql/algebra/operator/avg'
    autoload :BNode,              'sparql/algebra/operator/bnode'
    autoload :Bound,              'sparql/algebra/operator/bound'
    autoload :Ceil,               'sparql/algebra/operator/ceil'
    autoload :Count,              'sparql/algebra/operator/count'
    autoload :Datatype,           'sparql/algebra/operator/datatype'
    autoload :Day,                'sparql/algebra/operator/day'
    autoload :EncodeForURI,       'sparql/algebra/operator/encode_for_uri'
    autoload :Exists,             'sparql/algebra/operator/exists'
    autoload :Floor,              'sparql/algebra/operator/floor'
    autoload :Hours,              'sparql/algebra/operator/hours'
    autoload :IsBlank,            'sparql/algebra/operator/is_blank'
    autoload :IsIRI,              'sparql/algebra/operator/is_iri'
    autoload :IsLiteral,          'sparql/algebra/operator/is_literal'
    autoload :IsNumeric,          'sparql/algebra/operator/is_numeric'
    autoload :IsURI,              'sparql/algebra/operator/is_iri'
    autoload :IRI,                'sparql/algebra/operator/iri'
    autoload :Lang,               'sparql/algebra/operator/lang'
    autoload :LCase,              'sparql/algebra/operator/lcase'
    autoload :Max,                'sparql/algebra/operator/max'
    autoload :MD5,                'sparql/algebra/operator/md5'
    autoload :Min,                'sparql/algebra/operator/min'
    autoload :Minus,              'sparql/algebra/operator/minus'
    autoload :Minutes,            'sparql/algebra/operator/minutes'
    autoload :Month,              'sparql/algebra/operator/month'
    autoload :Negate,             'sparql/algebra/operator/negate'
    autoload :Not,                'sparql/algebra/operator/not'
    autoload :NotExists,          'sparql/algebra/operator/notexists'
    autoload :Plus,               'sparql/algebra/operator/plus'
    autoload :Round,              'sparql/algebra/operator/round'
    autoload :Sample,             'sparql/algebra/operator/sample'
    autoload :Seconds,            'sparql/algebra/operator/seconds'
    autoload :Sum,                'sparql/algebra/operator/sum'
    autoload :SHA1,               'sparql/algebra/operator/sha1'
    autoload :SHA256,             'sparql/algebra/operator/sha256'
    autoload :SHA512,             'sparql/algebra/operator/sha512'
    autoload :Str,                'sparql/algebra/operator/str'
    autoload :Timezone,           'sparql/algebra/operator/timezone'
    autoload :TZ,                 'sparql/algebra/operator/tz'
    autoload :Year,               'sparql/algebra/operator/year'

    # Binary operators
    autoload :And,                'sparql/algebra/operator/and'
    autoload :Compare,            'sparql/algebra/operator/compare'
    autoload :Concat,             'sparql/algebra/operator/concat'
    autoload :Contains,           'sparql/algebra/operator/contains'
    autoload :Divide,             'sparql/algebra/operator/divide'
    autoload :Equal,              'sparql/algebra/operator/equal'
    autoload :If,                 'sparql/algebra/operator/if'
    autoload :GreaterThan,        'sparql/algebra/operator/greater_than'
    autoload :GreaterThanOrEqual, 'sparql/algebra/operator/greater_than_or_equal'
    autoload :LangMatches,        'sparql/algebra/operator/lang_matches'
    autoload :LessThan,           'sparql/algebra/operator/less_than'
    autoload :LessThanOrEqual,    'sparql/algebra/operator/less_than_or_equal'
    autoload :Multiply,           'sparql/algebra/operator/multiply'
    autoload :NotEqual,           'sparql/algebra/operator/not_equal'
    autoload :Or,                 'sparql/algebra/operator/or'
    autoload :Regex,              'sparql/algebra/operator/regex'
    autoload :Replace,            'sparql/algebra/operator/replace'
    autoload :SameTerm,           'sparql/algebra/operator/same_term'
    autoload :StrAfter,           'sparql/algebra/operator/strafter'
    autoload :StrBefore,          'sparql/algebra/operator/strbefore'
    autoload :StrDT,              'sparql/algebra/operator/strdt'
    autoload :StrEnds,            'sparql/algebra/operator/strends'
    autoload :StrLang,            'sparql/algebra/operator/strlang'
    autoload :StrLen,             'sparql/algebra/operator/strlen'
    autoload :StrStarts,          'sparql/algebra/operator/strstarts'
    autoload :SubStr,             'sparql/algebra/operator/substr'
    autoload :Subtract,           'sparql/algebra/operator/subtract'
    autoload :UCase,              'sparql/algebra/operator/ucase'

    # Property Paths
    autoload :Alt,                'sparql/algebra/operator/alt'
    autoload :NotOneOf,           'sparql/algebra/operator/notoneof'
    autoload :PathOpt,            'sparql/algebra/operator/path_opt'
    autoload :PathPlus,           'sparql/algebra/operator/path_plus'
    autoload :PathStar,           'sparql/algebra/operator/path_star'
    autoload :Path,               'sparql/algebra/operator/path'
    autoload :Reverse,            'sparql/algebra/operator/reverse'
    autoload :Seq,                'sparql/algebra/operator/seq'
    autoload :Sequence,           'sparql/algebra/operator/sequence'

    # Miscellaneous
    autoload :Asc,                'sparql/algebra/operator/asc'
    autoload :Coalesce,           'sparql/algebra/operator/coalesce'
    autoload :Desc,               'sparql/algebra/operator/desc'
    autoload :Exprlist,           'sparql/algebra/operator/exprlist'
    autoload :GroupConcat,        'sparql/algebra/operator/group_concat'
    autoload :In,                 'sparql/algebra/operator/in'
    autoload :NotIn,              'sparql/algebra/operator/notin'

    # Query operators
    autoload :Ask,                'sparql/algebra/operator/ask'
    autoload :Base,               'sparql/algebra/operator/base'
    autoload :BGP,                'sparql/algebra/operator/bgp'
    autoload :Construct,          'sparql/algebra/operator/construct'
    autoload :Dataset,            'sparql/algebra/operator/dataset'
    autoload :Describe,           'sparql/algebra/operator/describe'
    autoload :Distinct,           'sparql/algebra/operator/distinct'
    autoload :Extend,             'sparql/algebra/operator/extend'
    autoload :Filter,             'sparql/algebra/operator/filter'
    autoload :Graph,              'sparql/algebra/operator/graph'
    autoload :Group,              'sparql/algebra/operator/group'
    autoload :Join,               'sparql/algebra/operator/join'
    autoload :LeftJoin,           'sparql/algebra/operator/left_join'
    autoload :Minus,              'sparql/algebra/operator/minus'
    autoload :Order,              'sparql/algebra/operator/order'
    autoload :Prefix,             'sparql/algebra/operator/prefix'
    autoload :Project,            'sparql/algebra/operator/project'
    autoload :Reduced,            'sparql/algebra/operator/reduced'
    autoload :Slice,              'sparql/algebra/operator/slice'
    autoload :Table,              'sparql/algebra/operator/table'
    autoload :Union,              'sparql/algebra/operator/union'

    # Update operators
    autoload :Add,                'sparql/algebra/operator/add'
    autoload :Clear,              'sparql/algebra/operator/clear'
    autoload :Copy,               'sparql/algebra/operator/copy'
    autoload :Create,             'sparql/algebra/operator/create'
    autoload :Delete,             'sparql/algebra/operator/delete'
    autoload :DeleteData,         'sparql/algebra/operator/delete_data'
    autoload :DeleteWhere,        'sparql/algebra/operator/delete_where'
    autoload :Drop,               'sparql/algebra/operator/drop'
    autoload :Insert,             'sparql/algebra/operator/insert'
    autoload :InsertData,         'sparql/algebra/operator/insert_data'
    autoload :Load,               'sparql/algebra/operator/load'
    autoload :Modify,             'sparql/algebra/operator/modify'
    autoload :Move,               'sparql/algebra/operator/move'
    autoload :Update,             'sparql/algebra/operator/update'
    autoload :Using,              'sparql/algebra/operator/using'
    autoload :With,               'sparql/algebra/operator/with'



    ##
    # Returns an operator class for the given operator `name`.
    #
    # @param  [Symbol, #to_s]  name
    # @param  [Integer] arity
    # @return [Class] an operator class, or `nil` if an operator was not found
    def self.for(name, arity = nil)
      # TODO: refactor this to dynamically introspect loaded operator classes.
      case (name.to_s.downcase.to_sym rescue nil)
        when :'!='            then NotEqual
        when :'/'             then Divide
        when :'='             then Equal
        when :*               then Multiply
        when :+               then Plus
        when :-               then arity.eql?(1) ? Negate : Subtract
        when :<               then LessThan
        when :<=              then LessThanOrEqual
        when :<=>             then Compare # non-standard
        when :>               then GreaterThan
        when :>=              then GreaterThanOrEqual
        when :abs             then Abs
        when :add             then Add
        when :alt             then Alt
        when :and, :'&&'      then And
        when :avg             then Avg
        when :bnode           then BNode
        when :bound           then Bound
        when :coalesce        then Coalesce
        when :ceil            then Ceil
        when :concat          then Concat
        when :contains        then Contains
        when :count           then Count
        when :datatype        then Datatype
        when :day             then Day
        when :encode_for_uri  then EncodeForURI
        when :divide          then Divide
        when :exists          then Exists
        when :floor           then Floor
        when :group_concat    then GroupConcat
        when :hours           then Hours
        when :if              then If
        when :in              then In
        when :iri, :uri       then IRI
        when :isblank         then IsBlank
        when :isiri           then IsIRI
        when :isliteral       then IsLiteral
        when :isnumeric       then IsNumeric
        when :isuri           then IsIRI # alias
        when :lang            then Lang
        when :langmatches     then LangMatches
        when :lcase           then LCase
        when :md5             then MD5
        when :max             then Max
        when :min             then Min
        when :minus           then Minus
        when :minutes         then Minutes
        when :month           then Month
        when :multiply        then Multiply
        when :not, :'!'       then Not
        when :notexists       then NotExists
        when :notin           then NotIn
        when :notoneof        then NotOneOf
        when :now             then Now
        when :or, :'||'       then Or
        when :path            then Path
        when :path?           then PathOpt
        when :"path*"         then PathStar
        when :"path+"         then PathPlus
        when :plus            then Plus
        when :rand            then Rand
        when :regex           then Regex
        when :replace         then Replace
        when :reverse         then Reverse
        when :round           then Round
        when :sameterm        then SameTerm
        when :sample          then Sample
        when :seconds         then Seconds
        when :seq             then Seq
        when :sequence        then Sequence
        when :sha1            then SHA1
        when :sha256          then SHA256
        when :sha512          then SHA512
        when :str             then Str
        when :strafter        then StrAfter
        when :strbefore       then StrBefore
        when :strdt           then StrDT
        when :strends         then StrEnds
        when :strlang         then StrLang
        when :strlen          then StrLen
        when :strstarts       then StrStarts
        when :struuid         then StrUUID
        when :substr          then SubStr
        when :subtract        then Subtract
        when :sum             then Sum
        when :timezone        then Timezone
        when :tz              then TZ
        when :ucase           then UCase
        when :uuid            then UUID
        when :year            then Year

        # Miscellaneous
        when :asc             then Asc
        when :desc            then Desc
        when :exprlist        then Exprlist

        # Datasets
        when :dataset         then Dataset

        # Query forms
        when :ask             then Ask
        when :base            then Base
        when :bgp             then BGP
        when :construct       then Construct
        when :describe        then Describe
        when :distinct        then Distinct
        when :extend          then Extend
        when :filter          then Filter
        when :graph           then Graph
        when :group           then Group
        when :join            then Join
        when :leftjoin        then LeftJoin
        when :order           then Order
        when :minus           then Minus
        when :prefix          then Prefix
        when :project         then Project
        when :reduced         then Reduced
        when :slice           then Slice
        when :table           then Table
        when :triple          then RDF::Query::Pattern
        when :union           then Union

        # Update forms
        when :add             then Add
        when :clear           then Clear
        when :copy            then Copy
        when :create          then Create
        when :delete          then Delete
        when :deletedata      then DeleteData
        when :deletewhere     then DeleteWhere
        when :drop            then Drop
        when :insert          then Insert
        when :insertdata      then InsertData
        when :load            then Load
        when :modify          then Modify
        when :move            then Move
        when :update          then Update
        when :using           then Using
        when :with            then With
        else                       nil # not found
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
    # @overload initialize(*operands)
    #   @param  [Array<RDF::Term>] operands
    #
    # @overload initialize(*operands, options)
    #   @param  [Array<RDF::Term>] operands
    #   @param  [Hash{Symbol => Object}] options
    #     any additional options
    #   @option options [Boolean] :memoize (false)
    #     whether to memoize results for particular operands
    # @raise  [TypeError] if any operand is invalid
    def initialize(*operands)
      @options  = operands.last.is_a?(Hash) ? operands.pop.dup : {}
      @operands = operands.map! do |operand|
        case operand
          when Array
            operand.each {|op| op.parent = self if operand.respond_to?(:parent=)}
            operand
          when Operator, Variable, RDF::Term, RDF::Query, RDF::Query::Pattern, Array, Symbol
            operand.parent = self if operand.respond_to?(:parent=)
            operand
          when TrueClass, FalseClass, Numeric, String, DateTime, Date, Time
            RDF::Literal(operand)
          when NilClass
            nil
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
    # @param [RDF::URI] uri
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
      operands.any?(&:variable?)
    end

    ##
    # Returns `true` if any of the operands are nodes, `false`
    # otherwise.
    #
    # @return [Boolean]
    def node?
      operands.any? do |operand|
        operand.respond_to?(:node?) ? operand.node? : operand.node?
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
    # Returns `true` if this is an aggregate
    #
    # Overridden in evaluatables which are aggregates
    #
    # @return [Boolean] `true` or `false`
    def aggregate?
      respond_to?(:aggregate)
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
        evaluate(RDF::Query::Solution.new) rescue self
      else
        super # returns `self`
      end
    end

    ##
    # Rewrite operands by yielding each operand. Recursively descends
    # through operands implementing this method.
    #
    # @yield operand
    # @yieldparam [] operand
    # @yieldreturn [SPARQL::Algebra::Expression] the re-written operand
    # @return [SPARQL::Algebra::Expression] `self`
    def rewrite(&block)
      @operands = @operands.map do |op|
        # Rewrite the operand
        unless new_op = block.call(op)
          # Not re-written, rewrite
          new_op = op.respond_to?(:rewrite) ? op.rewrite(&block) : op
        end
        new_op
      end
      self
    end

    ##
    # Returns the SPARQL S-Expression (SSE) representation of this operator.
    #
    # @return [Array]
    # @see    http://openjena.org/wiki/SSE
    def to_sxp_bin
      operator = [self.class.const_get(:NAME)].flatten.first
      [operator, *(operands || []).map(&:to_sxp_bin)]
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

      to_sxp_bin.to_sxp
    end

    ##
    # Returns a developer-friendly representation of this operator.
    #
    # @return [String]
    def inspect
      sprintf("#<%s:%#0x(%s)>", self.class.name, __id__, operands.to_sse.gsub(/\s+/m, ' '))
    end

    ##
    # @param  [Statement] other
    # @return [Boolean]
    def eql?(other)
      other.class == self.class && other.operands == self.operands
    end
    alias_method :==, :eql?

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
      operands.select {|o| o.respond_to?(:vars)}.map(&:vars).flatten
    end

    ##
    # Enumerate via depth-first recursive descent over operands, yielding each operator
    # @yield operator
    # @yieldparam [Object] operator
    # @return [Enumerator]
    def each_descendant(&block)
      if block_given?
        operands.each do |operand|
          case operand
          when Array
            operand.each do |op|
              op.each_descendant(&block) if op.respond_to?(:each_descendant)
              block.call(op)
            end
          else
            operand.each_descendant(&block) if operand.respond_to?(:each_descendant)
          end
          block.call(operand)
        end
      end
      enum_for(:each_descendant)
    end
    alias_method :descendants, :each_descendant
    alias_method :each, :each_descendant

    ##
    # Parent expression, if any
    #
    # @return [Operator]
    def parent; @options[:parent]; end

    ##
    # Parent operator, if any
    #
    # @return [Operator]
    def parent=(operator)
      @options[:parent]= operator
    end

    ##
    # First ancestor operator of type `klass`
    #
    # @param [Class] klass
    # @return [Operator]
    def first_ancestor(klass)
      parent.is_a?(klass) ? parent : parent.first_ancestor(klass) if parent
    end

    ##
    # Validate all operands, operator specific classes should override for operator-specific validation
    # @return [SPARQL::Algebra::Expression] `self`
    # @raise  [ArgumentError] if the value is invalid
    def validate!
      operands.each {|op| op.validate! if op.respond_to?(:validate!)}
      self
    end
  protected

    ##
    # Returns the effective boolean value (EBV) of the given `literal`.
    #
    # @param  [RDF::Literal] literal
    # @return [RDF::Literal::Boolean] `true` or `false`
    # @raise  [TypeError] if the literal could not be coerced to an `RDF::Literal::Boolean`
    # @see    http://www.w3.org/TR/sparql11-query/#ebv
    def boolean(literal)
      case literal
        when FalseClass then RDF::Literal::FALSE
        when TrueClass  then RDF::Literal::TRUE
        when RDF::Literal::Boolean
          # If the argument is a typed literal with a datatype of
          # `xsd:boolean`, the EBV is the value of that argument.
          # However, the EBV of any literal whose type is `xsd:boolean` is
          # false if the lexical form is not valid for that datatype.
          RDF::Literal(literal.valid? && literal.true?)
        when RDF::Literal::Numeric
          # If the argument is a numeric type or a typed literal with a
          # datatype derived from a numeric type, the EBV is false if the
          # operand value is NaN or is numerically equal to zero; otherwise
          # the EBV is true.
          # However, the EBV of any literal whose type is numeric is
          # false if the lexical form is not valid for that datatype.
          RDF::Literal(literal.valid? && !(literal.zero?) && !(literal.respond_to?(:nan?) && literal.nan?))
        else case
          when literal.is_a?(RDF::Literal) && literal.plain?
            # If the argument is a plain literal or a typed literal with a
            # datatype of `xsd:string`, the EBV is false if the operand value
            # has zero length; otherwise the EBV is true.
            RDF::Literal(!(literal.value.empty?))
          else
            # All other arguments, including unbound arguments, produce a type error.
            raise TypeError, "could not coerce #{literal.inspect} to an RDF::Literal::Boolean"
        end
      end
    end

    ##
    # Transform an array of expressions into a recursive set
    # of binary operations
    # e.g.: a || b || c => (|| a (|| b c))
    # @param [Class] klass Binary Operator class
    # @param [Array<SPARQL::Algebra::Expression>] expressions
    # @return [SPARQL::Algebra::Expression]
    def to_binary(klass, *expressions)
      case expressions.length
      when 0
        # Oops!
        raise "Operator#to_binary requires two or more expressions"
      when 1
        expressions.first
      when 2
        klass.new(*expressions)
      else
        klass.new(expressions.shift, to_binary(klass, *expressions))
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

    ##
    # A SPARQL quaternary operator.
    #
    # Operators of this kind take four operands.
    #
    # @abstract
    class Quaternary < Operator
      ARITY = 4

      ##
      # @param  [RDF::Term] arg1
      #   the first operand
      # @param  [RDF::Term] arg2
      #   the second operand
      # @param  [RDF::Term] arg3
      #   the third operand
      # @param  [RDF::Term] arg4
      #   the forth operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      def initialize(arg1, arg2, arg3, arg4, options = {})
        super
      end
    end # Ternary
  end # Operator
end; end # SPARQL::Algebra
