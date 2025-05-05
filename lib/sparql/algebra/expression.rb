module SPARQL; module Algebra
  ##
  # A SPARQL algebra expression.
  #
  # @abstract
  module Expression
    include RDF::Util::Logger

    # Operators for which `:triple` denotes a pattern, not a builtin
    PATTERN_PARENTS = [
      Operator::BGP,
      Operator::Construct,
      Operator::Delete,
      Operator::DeleteData,
      Operator::DeleteWhere,
      Operator::Graph,
      Operator::Insert,
      Operator::InsertData,
      Operator::Path,
    ].freeze

    ##
    # @example
    #   Expression.parse('(isLiteral 3.1415)')
    #
    # @param  [IO, String, #read, #to_s] sse
    #   a SPARQL S-Expression (SSE) string or IO object responding to #read
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see {Operator#initialize})
    # @option options [RDF::URI, #to_s] :base_uri
    #   Base URI used for loading relative URIs.
    #
    # @yield  [expression]
    # @yieldparam  [SPARQL::Algebra::Expression] expression
    # @yieldreturn [void] ignored
    # @return [Expression]
    def self.parse(sse, **options, &block)
      sse = sse.encode(Encoding::UTF_8)
      sxp = SXP::Reader::SPARQL.new(sse) do |reader|
        # Set base_uri if we have one
        reader.base_uri = options[:base_uri] if options[:base_uri]
      end
      sxp_result = sxp.read

      debug(options) {"base_uri: #{options[:base_uri]}"}
      Operator.base_uri = options.delete(:base_uri) if options.has_key?(:base_uri)
      Operator.prefixes = sxp.prefixes || {}

      expression = self.new(sxp_result, **options)

      yield(expression) if block_given?
      expression
    end

    ##
    # Parses input from the given file name or URL.
    #
    # @param  [String, #to_s] filename
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see {Operator#initialize})
    # @option options [RDF::URI, #to_s] :base_uri
    #   Base URI used for loading relative URIs.
    #
    # @yield  [expression]
    # @yieldparam  [SPARQL::Algebra::Expression] expression
    # @yieldreturn [void] ignored
    # @return [Expression]
    def self.open(filename, **options, &block)
      RDF::Util::File.open_file(filename, **options) do |file|
        options[:base_uri] ||= filename
        Expression.parse(file, **options, &block)
      end
    end

    ##
    # @example
    #   Expression.for(:isLiteral, RDF::Literal(3.1415))
    #   Expression[:isLiteral, RDF::Literal(3.1415)]
    #
    # @param  [Array] sse
    #   a SPARQL S-Expression (SSE) form
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see {Operator#initialize})
    # @return [Expression]
    def self.for(*sse, **options)
      self.new(sse, **options)
    end
    class << self; alias_method :[], :for; end

    ##
    # @example
    #   Expression.new([:isLiteral, RDF::Literal(3.1415)], version: 1.0)
    #
    # @param  [Array] sse
    #   a SPARQL S-Expression (SSE) form
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see {Operator#initialize})
    # @return [Expression]
    # @raise  [TypeError] if any of the operands is invalid
    def self.new(sse, parent_operator: nil, **options)
      raise ArgumentError, "invalid SPARQL::Algebra::Expression form: #{sse.inspect}" unless sse.is_a?(Array)

      operator = Operator.for(sse.first, sse.length - 1)

      # If we don't find an operator, and sse.first is an extension IRI, use a function call
      if !operator && sse.first.is_a?(RDF::URI) && self.extension?(sse.first)
        operator = Operator.for(:function_call, sse.length)
        sse.unshift(:function_call)
      end

      unless operator
        return case sse.first
        when Array
          debug(options) {"Map array elements #{sse}"}
          sse.map {|s| self.new(s, parent_operator: parent_operator, **options.merge(depth: options[:depth].to_i + 1))}
        else
          debug(options) {"No operator found for #{sse.first}"}
          sse.map do |s|
            s.is_a?(Array) ?
              self.new(s, parent_operator: parent_operator, depth: options[:depth].to_i + 1) :
              s
          end
        end
      end

      operands = sse[1..-1].map do |operand|
        debug(options) {"Operator=#{operator.inspect}, Operand=#{operand.inspect}"}
        case operand
          when Array
            self.new(operand, parent_operator: operator, **options.merge(depth: options[:depth].to_i + 1))
          when Operator, Variable, RDF::Term, RDF::Query, Symbol
            operand
          when TrueClass, FalseClass, Numeric, String, DateTime, Date, Time
            RDF::Literal(operand)
          else raise TypeError, "invalid SPARQL::Algebra::Expression operand: #{operand.inspect}"
        end
      end

      debug(options) {"#{operator.inspect}(#{operands.map(&:inspect).join(',')})"}
      logger = options[:logger]
      options.delete_if {|k, v| [:debug, :logger, :depth, :prefixes, :base_uri, :update, :validate].include?(k) }
      begin
        # Due to confusion over (triple) and special-case for (qtriple)
        if operator == RDF::Query::Pattern
          options = options.merge(tripleTerm: true) if sse.first == :qtriple
        elsif operator == Operator::Triple && PATTERN_PARENTS.include?(parent_operator)
          operator = RDF::Query::Pattern
        end
        operator.new(*operands, parent_operator: operator, **options)
      rescue ArgumentError => e
        if logger
          logger.error("Operator=#{operator.inspect}: #{e}")
        else
          raise "Operator=#{operator.inspect}: #{e}"
        end
      end
    end

    ##
    # Register an extension function.
    #
    # Extension functions take zero or more arguments of type `RDF::Term`
    # and return an argument of type `RDF::Term`, or raise `TypeError`.
    #
    # Functions are identified using the `uri` parameter and specified using a block.
    #
    # Arguments are evaluated, and the block is called with argument values (if a variable was unbound, an error will have been generated).
    # 
    # It is possible to get unevaluated arguments but care must be taken not to violate the rules of function evaluation.
    # 
    # Normally, block should be a pure evaluation based on it's arguments. It should not access a graph nor return different values for the same arguments (to allow expression optimization). Blocks can't bind a variables.
    #
    # @example registering a function definition applying the Ruby `crypt` method to its unary argument.
    #   SPARQL::Algebra::Expression.register_extension(RDF::URI("http://example/crypt") do |literal|
    #     raise TypeError, "argument must be a literal" unless literal.literal?
    #     RDF::Literal(literal.to_s.crypt("salt"))
    #   end
    #
    # @param [RDF::URI] uri
    # @yield *args
    # @yieldparam [Array<RDF::Term>] *args
    # @yieldreturn [RDF::Term]
    # @return [void]
    # @raise [TypeError] if `uri` is not an RDF::URI or no block is given
    def self.register_extension(uri, &block)
      raise TypeError, "uri must be an IRI" unless uri.is_a?(RDF::URI)
      raise TypeError, "must pass a block" unless block_given?
      self.extensions[uri] = block
    end

    ##
    # Registered extensions
    #
    # @return [Hash{RDF:URI: Proc}]
    def self.extensions
      @extensions ||= {}
    end

    ##
    # Is an extension function available?
    #
    # It's either a registered extension, or an XSD casting function
    #
    # @param [RDF::URI] function
    # @return [Boolean]
    def self.extension?(function)
      function.to_s.start_with?(RDF::XSD.to_s) || self.extensions[function]
    end

    ##
    # Invoke an extension function.
    #
    # Applies a registered extension function, if registered.
    # Otherwise, if it is an XSD Constructor function, apply
    # that.
    #
    # @param [RDF::URI] function
    # @param [Array<RDF::Term>] args splat of args to function
    # @return [RDF::Term]
    # @see https://www.w3.org/TR/sparql11-query/#extensionFunctions
    # @see https://www.w3.org/TR/sparql11-query/#FunctionMapping
    def self.extension(function, *args)
      if function.to_s.start_with?(RDF::XSD.to_s)
        self.cast(function, args.first)
      elsif extension_function = self.extensions[function]
        extension_function.call(*args)
      else
        raise TypeError, "Extension function #{function} not recognized"
      end
    end

    ##
    # Casts operand as the specified datatype
    #
    # @param [RDF::URI] datatype
    #   Datatype to evaluate, one of:
    #   xsd:integer, xsd:decimal xsd:float, xsd:double, xsd:string, xsd:boolean, xsd:dateTime, xsd:duration, xsd:dayTimeDuration, xsd:yearMonthDuration
    # @param [RDF::Term] value
    #   Value, which should be a typed literal, where the type must be that specified
    # @raise [TypeError] if datatype is not a URI or value cannot be cast to datatype
    # @return [RDF::Term]
    # @see https://www.w3.org/TR/sparql11-query/#FunctionMapping
    def self.cast(datatype, value)
      case datatype
      when RDF::XSD.date, RDF::XSD.time, RDF::XSD.dateTime
        case value
        when RDF::Literal::DateTime, RDF::Literal::Date, RDF::Literal::Time
          RDF::Literal.new(value, datatype: datatype)
        when RDF::Literal::Numeric, RDF::Literal::Boolean, RDF::URI, RDF::Node
          raise TypeError, "Value #{value.inspect} cannot be cast as #{datatype}"
        else
          RDF::Literal.new(value.value, datatype: datatype, validate: true)
        end
      when RDF::XSD.duration, RDF::XSD.dayTimeDuration, RDF::XSD.yearMonthDuration
        case value
        when RDF::Literal::Duration, RDF::Literal::DayTimeDuration, RDF::Literal::YearMonthDuration
          RDF::Literal.new(value, datatype: datatype, validate: true, canonicalize: true)
        when RDF::Literal::Numeric, RDF::Literal::Boolean, RDF::URI, RDF::Node
          raise TypeError, "Value #{value.inspect} cannot be cast as #{datatype}"
        else
          RDF::Literal.new(value.value, datatype: datatype, validate: true, canonicalize: true)
        end
      when RDF::XSD.float, RDF::XSD.double
        case value
        when RDF::Literal::Boolean
          RDF::Literal.new(value.object ? 1 : 0, datatype: datatype)
        when RDF::Literal::Numeric
          RDF::Literal.new(value.to_f, datatype: datatype)
        when RDF::Literal::DateTime, RDF::Literal::Date, RDF::Literal::Time, RDF::URI, RDF::Node
          raise TypeError, "Value #{value.inspect} cannot be cast as #{datatype}"
        else
          RDF::Literal.new(value.value, datatype: datatype, validate: true)
        end
      when RDF::XSD.boolean
        case value
        when RDF::Literal::Boolean
          value
        when RDF::Literal::Numeric
          RDF::Literal::Boolean.new(value.object != 0)
        when RDF::Literal::DateTime, RDF::Literal::Date, RDF::Literal::Time, RDF::URI, RDF::Node
          raise TypeError, "Value #{value.inspect} cannot be cast as #{datatype}"
        else
          RDF::Literal::Boolean.new(value.value, datatype: datatype, validate: true)
        end
      when RDF::XSD.decimal, RDF::XSD.integer
        case value
        when RDF::Literal::Boolean
          RDF::Literal.new(value.object ? 1 : 0, datatype: datatype)
        when RDF::Literal::Numeric
          RDF::Literal.new(value.object, datatype: datatype)
        when RDF::Literal::DateTime, RDF::Literal::Date, RDF::Literal::Time, RDF::URI, RDF::Node
          raise TypeError, "Value #{value.inspect} cannot be cast as #{datatype}"
        else
          RDF::Literal.new(value.value, datatype: datatype, validate: true)
        end
      when RDF::XSD.string
        # Cast to string rules based on https://www.w3.org/TR/xpath-functions/#casting-to-string
        case value
        when RDF::Literal::Integer
          RDF::Literal.new(value.canonicalize.to_s, datatype: datatype)
        when RDF::Literal::Decimal
          if value == value.ceil
            RDF::Literal.new(value.ceil, datatype: datatype)
          else
            RDF::Literal.new(value.canonicalize.to_s, datatype: datatype)
          end
        when RDF::Literal::Float, RDF::Literal::Double
          if value.abs >= 0.000001 && value.abs < 1000000
            # If SV has an absolute value that is greater than or equal to 0.000001 (one millionth) and less than 1000000 (one million), then the value is converted to an xs:decimal and the resulting xs:decimal is converted to an xs:string according to the rules above, as though using an implementation of xs:decimal that imposes no limits on the totalDigits or fractionDigits facets.
            cast(datatype, RDF::Literal::Decimal.new(value.object))
          elsif value.object.zero?
            # If SV has the value positive or negative zero, TV is "0" or "-0" respectively.
            RDF::Literal.new(value.to_s.start_with?('-') ? '-0' : '0', datatype: datatype)
          else
            # If SV is positive or negative infinity, TV is the string "INF" or "-INF" respectively.
            # In other cases, the result consists of a mantissa, which has the lexical form of an xs:decimal, followed by the letter "E", followed by an exponent which has the lexical form of an xs:integer. Leading zeroes and "+" signs are prohibited in the exponent. For the mantissa, there must be a decimal point, and there must be exactly one digit before the decimal point, which must be non-zero. The "+" sign is prohibited. There must be at least one digit after the decimal point. Apart from this mandatory digit, trailing zero digits are prohibited.
            RDF::Literal.new(value.canonicalize.to_s, datatype: datatype)
          end
        else
          RDF::Literal.new(value.canonicalize.to_s, datatype: datatype)
        end
      else
        raise TypeError, "Expected datatype (#{datatype}) to be a recognized XPath function"
      end
    rescue
      raise TypeError, $!.message
    end
    
    ##
    # Returns `false`.
    #
    # @return [Boolean] `true` or `false`
    # @see    #variable?
    def variable?
      false
    end

    ##
    # Returns `false`.
    #
    # @return [Boolean]
    def node?
      false
    end

    ##
    # Returns `true`.
    #
    # @return [Boolean] `true` or `false`
    # @see    #variable?
    def constant?
      !(variable?)
    end

    ##
    # Returns an optimized version of this expression.
    #
    # This is the default implementation, which simply returns a copy of `self`.
    # Subclasses can override this method in order to implement something
    # more useful.
    #
    # @param  [Hash{Symbol => Object}] options
    #   any additional options for optimization
    # @return [Expression] a copy of `self`
    # @see    RDF::Query#optimize
    def optimize(**options)
      self.deep_dup.optimize!(**options)
    end

    ##
    # Optimizes this query.
    #
    # @param  [Hash{Symbol => Object}] options
    #   any additional options for optimization
    # @return [self]
    # @see    RDF::Query#optimize!
    def optimize!(**options)
      self
    end

    ##
    # Evaluates this expression using the given variable `bindings`.
    #
    # This is the default implementation, which simply returns `self`.
    # Subclasses can override this method in order to implement something
    # more useful.
    #
    # @param  [RDF::Query::Solution] bindings
    #   a query solution containing zero or more variable bindings
    # @param [Hash{Symbol => Object}] options ({})
    #   options passed from query
    # @return [Expression] `self`
    def evaluate(bindings, **options)
      self
    end

    ##
    # Returns the SPARQL S-Expression (SSE) representation of this expression.
    #
    # This is the default implementation, which simply returns `self`.
    # Subclasses can override this method in order to implement something
    # more useful.
    #
    # @return [Array] `self`
    # @see    https://openjena.org/wiki/SSE
    def to_sxp_bin
      self
    end

    ##
    # Is this value valid, and composed only of valid components?
    #
    # @return [Boolean] `true` or `false`
    def valid?
      true
    end

    ##
    # Is this value invalid, or is it composed of any invalid components?
    #
    # @return [Boolean] `true` or `false`
    def invalid?
      !valid?
    end

    ##
    # Default validate! implementation, overridden in concrete classes
    # @return [SPARQL::Algebra::Expression] `self`
    # @raise  [ArgumentError] if the value is invalid
    def validate!
      raise ArgumentError, "#{self.inspect} is invalid" if invalid?
      self
    end
    alias_method :validate, :validate!

    private
    # @overload: May be called with node, message and an option hash
    #   @param [String] node processing node
    #   @param [String] message
    #   @param [Hash{Symbol => Object}] options
    #   @option options [Logger] :logger for logging progress
    #   @option options [Integer] :depth (@productions.length)
    #     Processing depth for indenting message output.
    #   @yieldreturn [String] appended to message, to allow for lazy-evaulation of message
    #
    # @overload: May be called with node and an option hash
    #   @param [String] node processing node
    #   @param [Hash{Symbol => Object}] options
    #   @option options [Logger] :logger for logging progress
    #   @option options [Integer] :depth (@productions.length)
    #     Processing depth for indenting message output.
    #   @yieldreturn [String] appended to message, to allow for lazy-evaulation of message
    #
    # @overload: May be called with only options, in which case the block is used to return the output message
    #   @param [String] node processing node
    #   @param [Hash{Symbol => Object}] options
    #   @option options [Logger] :logger for logging progress
    #   @option options [Integer] :depth (@productions.length)
    #     Processing depth for indenting message output.
    #   @yieldreturn [String] appended to message, to allow for lazy-evaulation of message
    def self.debug(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      return unless options[:logger]
      options[:logger].debug(*args, **options, &block)
    end
    
    def debug(*args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      log_debug(*args, **options, &block)
    end
  end # Expression
end; end # SPARQL::Algebra
