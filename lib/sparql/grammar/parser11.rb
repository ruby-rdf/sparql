require 'ebnf'
require 'ebnf/ll1/parser'
require 'sparql/grammar/meta'

module SPARQL::Grammar
  ##
  # A parser for the SPARQL 1.1 grammar.
  #
  # @see http://www.w3.org/TR/rdf-sparql-query/#grammar
  # @see http://en.wikipedia.org/wiki/LR_parser
  class Parser
    include SPARQL::Grammar::Meta
    include SPARQL::Grammar::Terminals
    include EBNF::LL1::Parser

    ##
    # Any additional options for the parser.
    #
    # @return [Hash]
    attr_reader   :options

    ##
    # The current input string being processed.
    #
    # @return [String]
    attr_accessor :input

    ##
    # The current input tokens being processed.
    #
    # @return [Array<Token>]
    attr_reader   :tokens

    ##
    # The internal representation of the result using hierarch of RDF objects and SPARQL::Algebra::Operator
    # objects.
    # @return [Array]
    # @see http://sparql.rubyforge.org/algebra
    attr_accessor :result

    # Terminals passed to lexer. Order matters!
    terminal(:ANON,                 ANON) do |parser, prod, token, input|
      input[:resource] = add_prod_datum(:BlankNode, parser.bnode)
    end
    terminal(:NIL,                  NIL) do |parser, prod, token, input|
      input[:resource] = add_prod_datum(:BlankNode, RDF['nil'])
    end
    terminal(:BLANK_NODE_LABEL,     BLANK_NODE_LABEL) do |parser, prod, token, input|
      input[:resource] = add_prod_datum(:BlankNode, parser.bnode(token.value[2..-1]))
    end
    terminal(:IRIREF,               IRIREF, :unescape => true) do |parser, prod, token, input|
      begin
        input[:resource] = parser.uri(token.value[1..-2])
      rescue ArgumentError => e
        raise Error, e.message
      end
    end
    terminal(:DOUBLE_POSITIVE,      DOUBLE) do |parser, prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      input[:resource] = parser.literal(value, :datatype => RDF::XSD.double)
    end
    terminal(:DECIMAL_POSITIVE,     DECIMAL) do |parser, prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      value = "0#{token.value}" if token.value[0,1] == "."
      input[:resource] = parser.literal(value, :datatype => RDF::XSD.decimal)
    end
    terminal(:INTEGER_POSITIVE,     INTEGER) do |parser, prod, token, input|
      input[:resource] = parser.literal(token.value, :datatype => RDF::XSD.integer)
    end
    terminal(:DOUBLE_NEGATIVE,      DOUBLE) do |parser, prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      input[:resource] = parser.literal(value, :datatype => RDF::XSD.double)
    end
    terminal(:DECIMAL_NEGATIVE,     DECIMAL) do |parser, prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      value = "0#{token.value}" if token.value[0,1] == "."
      input[:resource] = parser.literal(value, :datatype => RDF::XSD.decimal)
    end
    terminal(:INTEGER_NEGATIVE,     INTEGER) do |parser, prod, token, input|
      input[:resource] = parser.literal(token.value, :datatype => RDF::XSD.integer)
    end
    terminal(:DOUBLE,               DOUBLE) do |parser, prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      input[:resource] = parser.literal(value, :datatype => RDF::XSD.double)
    end
    terminal(:DECIMAL,              DECIMAL) do |parser, prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      value = "0#{token.value}" if token.value[0,1] == "."
      input[:resource] = parser.literal(value, :datatype => RDF::XSD.decimal)
    end
    terminal(:INTEGER,              INTEGER) do |parser, prod, token, input|
      input[:resource] = parser.literal(token.value, :datatype => RDF::XSD.integer)
    end
    terminal(:LANGTAG,              LANGTAG) do |parser, prod, token, input|
      input[:lang] = token.value[1..-1]
    end
    terminal(:PNAME_LN,             PNAME_LN, :unescape => true) do |parser, prod, token, input|
      prefix, suffix = token.value.split(":", 2)
      input[:resource] = parser.pname(prefix, suffix)
    end
    terminal(:PNAME_NS,             PNAME_NS) do |parser, prod, token, input|
      prefix = token.value[0..-2]
      
      # Two contexts, one when prefix is being defined, the other when being used
      case prod
      when :prefixID, :sparqlPrefix
        input[:prefix] = prefix
      else
        input[:resource] = parser.pname(prefix, '')
      end
    end
    terminal(:STRING_LITERAL_LONG1, STRING_LITERAL_LONG1, :unescape => true) do |parser, prod, token, input|
      input[:string_value] = token.value[3..-4]
    end
    terminal(:STRING_LITERAL_LONG2, STRING_LITERAL_LONG2, :unescape => true) do |parser, prod, token, input|
      input[:string_value] = token.value[3..-4]
    end
    terminal(:STRING_LITERAL1,      STRING_LITERAL1, :unescape => true) do |parser, prod, token, input|
      input[:string_value] = token.value[1..-2]
    end
    terminal(:STRING_LITERAL2,      STRING_LITERAL2, :unescape => true) do |parser, prod, token, input|
      input[:string_value] = token.value[1..-2]
    end
    terminal(:VAR1,                 VAR1) do |parser, prod, token, input|
      input[:resource] = parser.bnode(token.value[2..-1])
    end
    terminal(:VAR2,                 VAR1) do |parser, prod, token, input|
      input[:Var] = parser.variable(token.value[2..-1])
    end

    STR_EXPR = %r([\(\),.;\[\]a\{\}]
                 |&&|\+|\-|!=|!|<=|=|>=|<|>||\?|\^\^|\^|\|\||\|
                 |ABS|ADD|ALL|AS|ASC|ASK|BASE|BIND|BINDINGS
                 |BNODE|BOUND|BY|CEIL|CLEAR|COALESCE|CONCAT
                 |CONSTRUCT|CONTAINS|COPY|COUNT|CREATE|DATATYPE|DAY
                 |DEFAULT|DELETE\sDATA|DELETE\sWHERE|DELETE|DESC
                 |DESCRIBE|DISTINCT|DROP|ENCODE_FOR_URI|EXISTS
                 |FILTER|FLOOR|FROM|GRAPH|GROUP_CONCAT|GROUP|HAVING
                 |HOURS|IF|INSERT\sDATA|INSERT|INTO|IN|IRI
                 |LANGMATCHES|LANGTAG|LANG|LCASE|LIMIT|LOAD
                 |MAX|MD5|MINUS|MINUTES|MIN|MONTH|MOVE
                 |NAMED|NOT|NOW|OFFSET|OPTIONAL
                 |ORDER|PREFIX|RAND|REDUCED|REGEX|ROUND|SAMPLE|SECONDS
                 |SELECT|SEPARATOR|SERVICE
                 |SHA1|SHA224|SHA256|SHA384|SHA512
                 |STRDT|STRENDS|STRLAN|STRLEN|STRSTARTS|SUBSTR|STR|SUM
                 |TIMEZONE|TO|TZ|UCASE|UNDEF|UNION|URI|USING
                 |WHERE|WITH|YEAR
                 |isBLANK|isIRI|isLITERAL|isNUMERIC|sameTerm
                 |true
                 |false
                )x
    # String terminals
    terminal(nil,                  STR_EXPR) do |parser, prod, token, input|
      case token.value
      when 'a'             then input[:resource] = RDF.type
      when 'true', 'false' then input[:resource] = RDF::Literal::Boolean.new(token.value)
      else                      input[:string] = token.value
      end
    end

    # Productions
    # [2]  	Query	  ::=  	Prologue
    #                     ( SelectQuery | ConstructQuery | DescribeQuery | AskQuery ) BindingsClause
    production(:Query) do |parser, prod, token, input, data|
      return unless phase == :finish && data[:query]
      query = data[:query].first
      query = Algebra::Expression[:prefix, data[:PrefixDecl].first, query] if data[:PrefixDecl]
      query = Algebra::Expression[:base, data[:BaseDecl].first, query] if data[:BaseDecl]
      input[:query] = query
    end

    # [5]  	BaseDecl	  ::=  	'BASE' IRI_REF
    production(:BaseDecl) do |parser, phase, input, data, callback|
      next unless phase == :finish
      iri = data[:resource]
      callback.call(:trace, "BaseDecl", lambda {"Defined base as #{iri}"})
      add_prod_datum :BaseDecl, iri
      parser.options[:base_uri] = iri
    end

    # [6] PrefixDecl	  ::=  	'PREFIX' PNAME_NS IRI_REF
    production(:PrefixDecl) do |parser, phase, input, datadata, callback|
      next unless phase == :finish
      prefix = data[:prefix]
      iri = data[:resource]
      callback.call(:trace, "PrefixDecl", lambda {"Defined prefix #{prefix.inspect} mapping to #{iri.inspect}"})
      add_prod_datum :PrefixDecl, ["#{prefix}:", iri]
      parser.prefix(prefix, iri)
    end
    
    # [7]  	SelectQuery	  ::=  	SelectClause DatasetClause* WhereClause SolutionModifier
    production(:SelectQuery) do |parser, phase, input, data, callback|
      next unless phase == :finish
      add_prod_datum :query, query
    end

    # [10]  	ConstructQuery	  ::=  	'CONSTRUCT'
    #                                  ( ConstructTemplate DatasetClause* WhereClause SolutionModifier | DatasetClause* 'WHERE' '{' TriplesTemplate? '}' SolutionModifier )
    production(:ConstructQuery) do |parser, phase, input, data, callback|
      return unless phase == :finish
      query = parser.merge_modifiers(data)
      template = data[:ConstructTemplate] || []
      add_prod_datum :query, Algebra::Expression[:construct, template, query]
    end

    # [11]  	DescribeQuery	  ::=  	'DESCRIBE' ( VarOrIRIref+ | '*' )
    #                             DatasetClause* WhereClause? SolutionModifier
    production(:DescribeQuery) do |parser, phase, input, data, callback|
      return unless phase == :finish
      query = parser.merge_modifiers(data)
      to_describe = data[:VarOrIRIref] || []
      add_prod_datum :query, Algebra::Expression[:describe, to_describe, query]
    end

    # [12]  	AskQuery	  ::=  	'ASK' DatasetClause* WhereClause
    production(:DescribeQuery) do |parser, phase, input, data, callback|
      return unless phase == :finish
      query = parser.merge_modifiers(data)
      add_prod_datum :query, Algebra::Expression[:ask, query]
    end

    # [14]  	DefaultGraphClause	  ::=  	SourceSelector
    production(:DefaultGraphClause) do |parser, phase, input, data, callback|
      add_prod_datum :dataset, data[:IRIref] if phase == :finish
    end

    # [15]  	NamedGraphClause	  ::=  	'NAMED' SourceSelector
    production(:NamedGraphClause) do |parser, phase, input, data, callback|
      add_prod_datum :dataset, data[:IRIref].unshift(:named) if phase == :finish
    end

    # [18]  	SolutionModifier	  ::=  	GroupClause? HavingClause? OrderClause? LimitOffsetClauses?

    # [19]  	GroupClause	  ::=  	'GROUP' 'BY' GroupCondition+
    #production(:GroupClause) do |parser, phase, input, data, callback|
    #end

    # [20]  	GroupCondition	  ::=  	BuiltInCall | FunctionCall
    #                                | '(' Expression ( 'AS' Var )? ')' | Var
    #production(:GroupClause) do |parser, phase, input, data, callback|
    #end

    # [21]  	HavingClause	  ::=  	'HAVING' HavingCondition+
    #production(:GroupClause) do |parser, phase, input, data, callback|
    #end

    # [23]  	OrderClause	  ::=  	'ORDER' 'BY' OrderCondition+
    production(:OrderClause) do |parser, phase, input, data, callback|
      return unless phase == :finish || (res = data[:OrderCondition]).nil?
      res = [res] if [:asc, :desc].include?(res[0]) # Special case when there's only one condition and it's ASC (x) or DESC (x)
      add_prod_data :order, res
    end

    # [24]  	OrderCondition	  ::=  	 ( ( 'ASC' | 'DESC' )
    #                                 BrackettedExpression )
    #                               | ( Constraint | Var )
    production(:OrderCondition) do |parser, phase, input, data, callback|
      return unless phase == :finish
      if data[:OrderDirection]
        add_prod_datum(:OrderCondition, Algebra::Expression.for(data[:OrderDirection] + data[:Expression]))
      else
        add_prod_datum(:OrderCondition, data[:Constraint] || data[:Var])
      end
    end

    # [25]  	LimitOffsetClauses	  ::=  	LimitClause OffsetClause?
    #                                 | OffsetClause LimitClause?
    production(:LimitOffsetClauses) do |parser, phase, input, data, callback|
      return unless phase == :finish && (data[:limit] || data[:offset])
      limit = data[:limit] ? data[:limit].last : :_
      offset = data[:offset] ? data[:offset].last : :_
      add_prod_data :slice, offset, limit
    end

    # [26]  	LimitClause	  ::=  	'LIMIT' INTEGER
    production(:LimitClause) do |parser, phase, input, data, callback|
      add_prod_datum(:limit, data[:literal]) if phase == :finish
    end

    # [27]  	OffsetClause	  ::=  	'OFFSET' INTEGER
    production(:OffsetClause) do |parser, phase, input, data, callback|
      add_prod_datum(:offset, data[:literal]) if phase == :finish
    end

    # [54]  	[55]  	GroupGraphPatternSub	  ::=  	TriplesBlock?
    #                                             ( GraphPatternNotTriples '.'? TriplesBlock? )*
    production(:GroupGraphPatternSub) do |parser, phase, input, data, callback|
      return unless phase == :finish
      query_list = data[:query_list]
      callback.call :trace, "GroupGraphPatternSub", lambda {"ql #{query_list.to_a.inspect}"}
      callback.call :trace, "GroupGraphPatternSub", lambda {"q #{data[:query] ? data[:query].first.inspect : 'nil'}"}
            
      if query_list
        lhs = data[:query].to_a.first
        while !query_list.empty?
          rhs = query_list.shift
          # Make the right-hand-side a Join with only a single operand, if it's not already and Operator
          rhs = Algebra::Expression.for(:join, :placeholder, rhs) unless rhs.is_a?(Algebra::Operator)
          callback.call :trace, "GroupGraphPatternSub", lambda {"<= q: #{rhs.inspect}"}
          callback.call :trace, "GroupGraphPatternSub", lambda {"<= lhs: #{lhs ? lhs.inspect : 'nil'}"}
          lhs ||= Algebra::Operator::BGP.new if rhs.is_a?(Algebra::Operator::LeftJoin)
          if lhs
            if rhs.operand(0) == :placeholder
              rhs.operands[0] = lhs
            else
              rhs = Algebra::Operator::Join.new(lhs, rhs)
            end
          end
          lhs = rhs
          lhs = lhs.operand(1) if lhs.operand(0) == :placeholder
          callback.call :trace, "GroupGraphPatternSub(itr)", lambda {"=> lhs: #{lhs.inspect}"}
        end
        # Trivial simplification for :join or :union of one query
        case lhs
        when Algebra::Operator::Join, Algebra::Operator::Union
          if lhs.operand(0) == :placeholder
            lhs = lhs.operand(1)
            callback.call :trace, "GroupGraphPatternSub(simplify)", lambda {"=> lhs: #{lhs.inspect}"}
          end
        end
        res = lhs
      elsif data[:query]
        res = data[:query].first
      end
            
      callback.call :trace, "GroupGraphPatternSub(pre-filter)", lambda {"res: #{res.inspect}"}

      if data[:filter]
        expr, query = parser.flatten_filter(data[:filter])
        query = res || Algebra::Operator::BGP.new
        # query should be nil
        res = Algebra::Operator::Filter.new(expr, query)
      end
      add_prod_datum(:query, res)
    end

    # [56]  	TriplesBlock	  ::=  	TriplesSameSubjectPath
    #                               ( '.' TriplesBlock? )?
    production(:TriplesBlock) do |parser, phase, input, data, callback|
      return unless phase == :finish
      query = Algebra::Operator::BGP.new
      data[:pattern].each {|p| query << p}
        
      # Append triples from ('.' TriplesBlock? )?
      data[:query].to_a.each {|q| query += q}
      add_prod_datum(:query, query)
    end

    # [57]  	GraphPatternNotTriples	  ::=  	GroupOrUnionGraphPattern
    #                                       | OptionalGraphPattern
    #                                       | MinusGraphPattern
    #                                       | GraphGraphPattern
    #                                       | ServiceGraphPattern
    #                                       | Filter | Bind
    production(:GraphPatternNotTriples) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:filter, data[:filter])

      if data[:query]
        res = data[:query].to_a.first
        res = Algebra::Expression.for(:join, :placeholder, res) unless res.is_a?(Algebra::Operator)
        add_prod_data(:GraphPatternNotTriples, res)
      end
    end

    # [58]  	OptionalGraphPattern	  ::=  	'OPTIONAL' GroupGraphPattern
    production(:OptionalGraphPattern) do |parser, phase, input, data, callback|
      return unless phase == :finish
      if data[:query]
        expr = nil
        query = data[:query].first
        if query.is_a?(Algebra::Operator::Filter)
          # Change to expression on left-join with query element
          expr, query = query.operands
          add_prod_data(:query, Algebra::Expression.for(:leftjoin, :placeholder, query, expr))
        else
          add_prod_data(:query, Algebra::Expression.for(:leftjoin, :placeholder, query))
        end
      end
    end

    # [59]  	GraphGraphPattern	  ::=  	'GRAPH' VarOrIRIref GroupGraphPattern
    production(:GraphGraphPattern) do |parser, phase, input, data, callback|
      return unless phase == :finish || data[:query].nil?
      name = (data[:VarOrIRIref]).last
      bgp = data[:query].first
      if name
        add_prod_data(:query, Algebra::Expression.for(:graph, name, bgp))
      else
        add_prod_data(:query, bgp)
      end
    end

    # [63]  	GroupOrUnionGraphPattern	  ::=  	GroupGraphPattern
    #                                           ( 'UNION' GroupGraphPattern )*
    production(:GroupOrUnionGraphPattern) do |parser, phase, input, data, callback|
      return unless phase == :finish
      res = data[:query].to_a.first
      if data[:union]
        while !data[:union].empty?
          # Join union patterns together as Union operators
          #puts "res: res: #{res}, input_prod: #{input_prod}, data[:union]: #{data[:union].first}"
          lhs = res
          rhs = data[:union].shift
          res = Algebra::Expression.for(:union, lhs, rhs)
        end
      end
      add_prod_datum(:query, res)
    end

    # ( 'UNION' GroupGraphPattern )*
    production(:_UNION_GroupGraphPattern_Star) do |parser, phase, input, data, callback|
      return unless phase == :finish
      # Add [:union rhs] to stack based on ":union"
      add_prod_data(:union, data[:query].to_a.first)
      add_prod_data(:union, data[:union].first) if data[:union]
    end

    # [64]  	Filter	  ::=  	'FILTER' Constraint
    production(:Filter) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:filter, data[:Constraint])
    end

    # [65]  	Constraint	  ::=  	BrackettedExpression | BuiltInCall
    #                           | FunctionCall
    production(:Constraint) do |parser, phase, input, data, callback|
      return unless phase == :finish
      if data[:Expression]
        # Resolve expression to the point it is either an atom or an s-exp
        add_prod_data(:Constraint, data[:Expression].to_a.first)
      elsif data[:BuiltInCall]
        add_prod_datum(:Constraint, data[:BuiltInCall])
      elsif data[:Function]
        add_prod_datum(:Constraint, data[:Function])
      end
    end

    # [66]  	FunctionCall	  ::=  	IRIref ArgList
    production(:FunctionCall) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_data(:Function, data[:IRIref] + data[:ArgList])
    end

    # [67]  	ArgList	  ::=  	NIL
    #                     | '(' 'DISTINCT'? Expression ( ',' Expression )* ')'
    production(:ArgList) do |parser, phase, input, data, callback|
      return unless phase == :finish
      data.values.each {|v| add_prod_datum(:ArgList, v)}
    end

    # [68]  	ExpressionList	  ::=  	NIL
    #                             | '(' Expression ( ',' Expression )* ')'
    production(:ExpressionList) do |parser, phase, input, data, callback|
      return unless phase == :finish
      data.values.each {|v| add_prod_datum(:ExpressionList, v)}
    end

    # [69]  	ConstructTemplate	  ::=  	'{' ConstructTriples? '}'
    production(:ConstructTemplate) do |parser, phase, input, data, callback|
      case phase
      when :start
        # Generate BNodes instead of non-distinguished variables
        @nd_var_gen = false
      when :finish
        @nd_var_gen = "0"
        add_prod_datum(:ConstructTemplate, data[:pattern])
        add_prod_datum(:ConstructTemplate, data[:ConstructTemplate])
      end
    end

    # [71]  	TriplesSameSubject	  ::=  	VarOrTerm PropertyListNotEmpty
    #                                 |	TriplesNode PropertyList
    production(:TriplesSameSubject) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:pattern, data[:pattern])
    end

    # [72]  	PropertyListNotEmpty	  ::=  	Verb ObjectList
    #                                       ( ';' ( Verb ObjectList )? )*
    production(:PropertyListNotEmpty) do |parser, phase, input, data, callback|
      case phase
      when :start
        subject = input[:VarOrTerm] || input[:TriplesNode] || input[:GraphNode]
        parser.error(nil, "Expected VarOrTerm or TriplesNode or GraphNode", :production => :PropertyListNotEmpty) if parser.validate? && !subject
        data[:Subject] = subject
      when :finish
        @nd_var_gen = "0"
        add_prod_datum(:ConstructTemplate, data[:pattern])
        add_prod_datum(:ConstructTemplate, data[:ConstructTemplate])
      end
    end

    # [74]  	ObjectList	  ::=  	Object ( ',' Object )*
    production(:ObjectList) do |parser, phase, input, data, callback|
      case phase
      when :start
        # Called after Verb. The prod_data stack should have Subject and Verb elements
        data[:Subject] = prod_data[:Subject]
        parser.error(nil, "Expected Subject", :production => :ObjectList) if !prod_data[:Subject] && parser.validate?
        parser.error(nil, "Expected Verb", :production => :ObjectList) if !prod_data[:Verb] && parser.validate?
        data[:Subject] = prod_data[:Subject]
        data[:Verb] = prod_data[:Verb].to_a.last
      when :finish
        @nd_var_gen = "0"
        add_prod_datum(:ConstructTemplate, data[:pattern])
        add_prod_datum(:ConstructTemplate, data[:ConstructTemplate])
      end
    end

    # [75]  	Object	  ::=  	GraphNode
    production(:Object) do |parser, phase, input, data, callback|
      return unless phase == :finish
      object = data[:VarOrTerm] || data[:TriplesNode] || data[:GraphNode]
      if object
        add_pattern(:Object, :subject => prod_data[:Subject], :predicate => prod_data[:Verb], :object => object)
        add_prod_datum(:pattern, data[:pattern])
      end
    end

    # [76]  	Verb	  ::=  	VarOrIRIref | 'a'
    production(:Verb) do |parser, phase, input, data, callback|
      return unless phase == :finish
      data.values.each {|v| add_prod_datum(:Verb, v)}
    end

    # [92]  	TriplesNode	  ::=  	Collection |	BlankNodePropertyList
    production(:TriplesNode) do |parser, phase, input, data, callback|
      case phase
      when :start
        # Called after Verb. The prod_data stack should have Subject and Verb elements
        data[:TriplesNode] = parser.bnode
      when :finish
        if input[:object_list]
          # Part of an rdf:List collection
          add_prod_data(:object_list, data[:pattern])
        else
          add_prod_datum(:pattern, data[:pattern])
          add_prod_datum(:TriplesNode, data[:TriplesNode])
        end
      end
    end

    # [94]  	Collection	  ::=  	'(' GraphNode+ ')'
    production(:Collection) do |parser, phase, input, data, callback|
      case phase
      when :start
        # Tells the TriplesNode production to collect and not generate statements
        data[:object_list] = []
      when :finish
        # Create a Collection using rdf:first/rdf:rest
        bnode = parser.bnode
        objects = current[:object_list]
        list = RDF::List.new(bnode, nil, objects)
        list.each_statement do |statement|
          next if statement.predicate == RDF.type && statement.object == RDF.List
          add_pattern(:Collection, :subject => statement.subject, :predicate => statement.predicate, :object => statement.object)
        end
      end
    end

    # [95]  	GraphNode	  ::=  	VarOrTerm |	TriplesNode
    production(:GraphNode) do |parser, phase, input, data, callback|
      return unless phase == :finish
      term = data[:VarOrTerm] || data[:TriplesNode]
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:GraphNode, term)
    end

    # [96]  	VarOrTerm	  ::=  	Var | GraphTerm
    production(:VarOrTerm) do |parser, phase, input, data, callback|
      return unless phase == :finish
      data.values.each {|v| add_prod_datum(:VarOrTerm, v)}
    end

    # [97]  	VarOrIRIref	  ::=  	Var | IRIref
    production(:VarOrIRIref) do |parser, phase, input, data, callback|
      return unless phase == :finish
      data.values.each {|v| add_prod_datum(:VarOrIRIref, v)}
    end

    # [99]  	GraphTerm	  ::=  	IRIref |	RDFLiteral |	NumericLiteral
    #                         |	BooleanLiteral |	BlankNode |	NIL
    production(:GraphTerm) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:GraphTerm, data[:IRIref] || data[:literal] || data[:BlankNode] || data[:NIL])
    end

    # [100]  	Expression	  ::=  	ConditionalOrExpression
    production(:Expression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:Expression, data[:Expression])
    end

    # [101]  	ConditionalOrExpression	  ::=  	ConditionalAndExpression
    #                                         ( '||' ConditionalAndExpression )*
    production(:ConditionalOrExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_operator_expressions(:_OR, data)
    end

    # ( '||' ConditionalAndExpression )*
    production(:_OR_ConditionalAndExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      accumulate_operator_expressions(:ConditionalOrExpression, :_OR, data)
    end

    # [102]  	ConditionalAndExpression	  ::=  	ValueLogical ( '&&' ValueLogical )*
    production(:ConditionalAndExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_operator_expressions(:_AND, data)
    end

    # ( '||' ConditionalAndExpression )*
    production(:_AND_ValueLogical_Star) do |parser, phase, input, data, callback|
      return unless phase == :finish
      accumulate_operator_expressions(:ConditionalAndExpression, :_AND, data)
    end

    # [104]  	RelationalExpression	  ::=  	NumericExpression
    #                                       ( '=' NumericExpression
    #                                        | '!=' NumericExpression
    #                                        | '<' NumericExpression
    #                                        | '>' NumericExpression
    #                                        | '<=' NumericExpression
    #                                        | '>=' NumericExpression
    #                                        | 'IN' ExpressionList
    #                                        | 'NOT' 'IN' ExpressionList
    #                                        )?
    production(:RelationalExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      if data[:_Compare_Numeric]
        add_prod_datum(:Expression, Algebra::Expression.for(data[:_Compare_Numeric].insert(1, *data[:Expression])))
      else
        # NumericExpression with no comparitor
        add_prod_datum(:Expression, data[:Expression])
      end
    end

    # [106]  	AdditiveExpression	  ::=  	MultiplicativeExpression
    #                                     ( '+' MultiplicativeExpression
    #                                     | '-' MultiplicativeExpression
    #                                     | ( NumericLiteralPositive | NumericLiteralNegative )
    #                                       ( ( '*' UnaryExpression )
    #                                     | ( '/' UnaryExpression ) )?
    #                                     )*
    production(:AdditiveExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_operator_expressions(:_Add_Sub, data)
    end

    # ( '+' MultiplicativeExpression
    # | '-' MultiplicativeExpression
    # | ( NumericLiteralPositive | NumericLiteralNegative )
    #   ( ( '*' UnaryExpression )
    # | ( '/' UnaryExpression ) )?
    # )*
    production(:_Add_Sub_MultiplicativeExpression_Star) do |parser, phase, input, data, callback|
      return unless phase == :finish
      accumulate_operator_expressions(:AdditiveExpression, :_Add_Sub, data)
    end

    # [107]  	MultiplicativeExpression	  ::=  	UnaryExpression
    #                                           ( '*' UnaryExpression
    #                                           | '/' UnaryExpression )*
    production(:MultiplicativeExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_operator_expressions(:_Mul_Div, data)
    end

    # ( '*' UnaryExpression
    # | '/' UnaryExpression )*
    production(:_Mul_Div_UnaryExpression_Star) do |parser, phase, input, data, callback|
      return unless phase == :finish
      accumulate_operator_expressions(:MultiplicativeExpression, :_Mul_Div, data)
    end

    # [108]  	UnaryExpression	  ::=  	  '!' PrimaryExpression 
    #                                 |	'+' PrimaryExpression 
    #                                 |	'-' PrimaryExpression 
    #                                 |	PrimaryExpression
    production(:UnaryExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      case data[:UnaryExpression]
      when [:"!"]
        add_prod_datum(:Expression, Algebra::Expression[:not, data[:Expression].first])
      when [:"-"]
        e = data[:Expression].first
        if e.is_a?(RDF::Literal::Numeric)
          add_prod_datum(:Expression, -e) # Simple optimization to match ARQ generation
        else
          add_prod_datum(:Expression, Algebra::Expression[:minus, e])
        end
      else
        add_prod_datum(:Expression, data[:Expression])
      end
    end

    # [109]  	PrimaryExpression	  ::=  	BrackettedExpression | BuiltInCall
    #                                 | IRIrefOrFunction | RDFLiteral
    #                                 | NumericLiteral | BooleanLiteral
    #                                 | Var | Aggregate
    production(:PrimaryExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      if data[:Expression]
        add_prod_datum(:Expression, data[:Expression])
      elsif data[:BuiltInCall]
        add_prod_datum(:Expression, data[:BuiltInCall])
      elsif data[:IRIref]
        add_prod_datum(:Expression, data[:IRIref])
      elsif data[:Function]
        add_prod_datum(:Expression, data[:Function]) # Maintain array representation
      elsif data[:literal]
        add_prod_datum(:Expression, data[:literal])
      elsif data[:Var]
        add_prod_datum(:Expression, data[:Var])
      end

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [111]  	BuiltInCall	  ::=  	  'STR' '(' Expression ')' 
    #                               |	'LANG' '(' Expression ')' 
    #                               |	'LANGMATCHES' '(' Expression ',' Expression ')' 
    #                               |	'DATATYPE' '(' Expression ')' 
    #                               |	'BOUND' '(' Var ')' 
    #                               |	'IRI' '(' Expression ')' 
    #                               |	'URI' '(' Expression ')' 
    #                               |	'BNODE' ( '(' Expression ')' | NIL ) 
    #                               |	'RAND' NIL 
    #                               |	'ABS' '(' Expression ')' 
    #                               |	'CEIL' '(' Expression ')' 
    #                               |	'FLOOR' '(' Expression ')' 
    #                               |	'ROUND' '(' Expression ')' 
    #                               |	'CONCAT' ExpressionList 
    #                               |	SubstringExpression 
    #                               |	'STRLEN' '(' Expression ')' 
    #                               |	'UCASE' '(' Expression ')' 
    #                               |	'LCASE' '(' Expression ')' 
    #                               |	'ENCODE_FOR_URI' '(' Expression ')' 
    #                               |	'CONTAINS' '(' Expression ',' Expression ')' 
    #                               |	'STRSTARTS' '(' Expression ',' Expression ')' 
    #                               |	'STRENDS' '(' Expression ',' Expression ')' 
    #                               |	'YEAR' '(' Expression ')' 
    #                               |	'MONTH' '(' Expression ')' 
    #                               |	'DAY' '(' Expression ')' 
    #                               |	'HOURS' '(' Expression ')' 
    #                               |	'MINUTES' '(' Expression ')' 
    #                               |	'SECONDS' '(' Expression ')' 
    #                               |	'TIMEZONE' '(' Expression ')' 
    #                               |	'TZ' '(' Expression ')' 
    #                               |	'NOW' NIL 
    #                               |	'MD5' '(' Expression ')' 
    #                               |	'SHA1' '(' Expression ')' 
    #                               |	'SHA224' '(' Expression ')' 
    #                               |	'SHA256' '(' Expression ')' 
    #                               |	'SHA384' '(' Expression ')' 
    #                               |	'SHA512' '(' Expression ')' 
    #                               |	'COALESCE' ExpressionList 
    #                               |	'IF' '(' Expression ',' Expression ',' Expression ')' 
    #                               |	'STRLANG' '(' Expression ',' Expression ')' 
    #                               |	'STRDT' '(' Expression ',' Expression ')' 
    #                               |	'sameTerm' '(' Expression ',' Expression ')' 
    #                               |	'isIRI' '(' Expression ')' 
    #                               |	'isURI' '(' Expression ')' 
    #                               |	'isBLANK' '(' Expression ')' 
    #                               |	'isLITERAL' '(' Expression ')' 
    #                               |	'isNUMERIC' '(' Expression ')' 
    #                               |	RegexExpression 
    #                               |	ExistsFunc 
    #                               |	NotExistsFunc
    production(:BuiltInCall) do |parser, phase, input, data, callback|
      return unless phase == :finish
      if data[:regex]
        add_prod_datum(:BuiltInCall, Algebra::Expression.for(data[:regex].unshift(:regex)))
      elsif data[:substr]
        add_prod_datum(:BuiltInCall, Algebra::Expression.for(data[:substr].unshift(:substr)))
      elsif data[:exists]
        add_prod_datum(:BuiltInCall, Algebra::Expression.for(data[:exists].unshift(:exists)))
      elsif data[:not_exists]
        add_prod_datum(:BuiltInCall, Algebra::Expression.for(data[:not_exists].unshift(:not_exists)))
      elsif data[:BOUND]
        add_prod_datum(:BuiltInCall, Algebra::Expression.for(data[:Var].unshift(:bound)))
      elsif data[:BuiltInCall]
        add_prod_datum(:BuiltInCall, Algebra::Expression.for(data[:BuiltInCall] + data[:Expression]))
      end
    end

    # [112]  	RegexExpression	  ::=  	'REGEX' '(' Expression ',' Expression
    #                                 ( ',' Expression )? ')'
    production(:RegexExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:regex, data[:Expression])
    end

    # [113]  	SubstringExpression	  ::=  	'SUBSTR'
    #                                     '(' Expression ',' Expression
    #                                     ( ',' Expression )? ')'
    production(:SubstringExpression) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:substr, data[:Expression])
    end

    # [114]  	ExistsFunc	  ::=  	'EXISTS' GroupGraphPattern
    production(:ExistsFunc) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:exists, data[:query])
    end

    # [115]  	NotExistsFunc	  ::=  	'NOT' 'EXISTS' GroupGraphPattern
    production(:NotExistsFunc) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:not_exists, data[:query])
    end

    # [117]  	IRIrefOrFunction	  ::=  	IRIref ArgList?
    production(:IRIrefOrFunction) do |parser, phase, input, data, callback|
      return unless phase == :finish
      if data.has_key?(:ArgList)
        # Function is (func arg1 arg2 ...)
        add_prod_data(:Function, data[:IRIref] + data[:ArgList])
      else
        add_prod_datum(:IRIref, data[:IRIref])
      end
    end

    # [118]  	RDFLiteral	  ::=  	String ( LANGTAG | ( '^^' IRIref ) )?
    production(:RDFLiteral) do |parser, phase, input, data, callback|
      return unless phase == :finish || data[:string].nil?
      lit = data.dup
      str = lit.delete(:string).last 
      lit[:datatype] = lit.delete(:IRIref).last if lit[:IRIref]
      lit[:language] = lit.delete(:language).last.downcase if lit[:language]
      add_prod_datum(:literal, RDF::Literal.new(str, lit)) if str
    end

    # [121]  	NumericLiteralPositive	  ::=  	INTEGER_POSITIVE
    #                                       |	DECIMAL_POSITIVE
    #                                       |	DOUBLE_POSITIVE
    production(:NumericLiteralPositive) do |parser, phase, input, data, callback|
      return unless phase == :finish
      num = data.values.flatten.last
      add_prod_datum(:literal, parser.num.class.new("+#{num.value}"))

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [122]  	NumericLiteralNegative	  ::=  	INTEGER_NEGATIVE
    #                                       |	DECIMAL_NEGATIVE
    #                                       |	DOUBLE_NEGATIVE
    production(:NumericLiteralNegative) do |parser, phase, input, data, callback|
      return unless phase == :finish
      num = data.values.flatten.last
      add_prod_datum(:literal, parser.num.class.new("-#{num.value}"))

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [125]  	IRIref	  ::=  	IRI_REF |	PrefixedName
    production(:IRIref) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:IRIref, data[:iri])
    end

    # [126]  	PrefixedName	  ::=  	PNAME_LN | PNAME_NS
    production(:IRIref) do |parser, phase, input, data, callback|
      return unless phase == :finish
      add_prod_datum(:iri, data[:PrefixedName])
    end

    ##
    # Initializes a new parser instance.
    #
    # @param  [String, #to_s]          input
    # @param  [Hash{Symbol => Object}] options
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (for acessing intermediate parser productions)
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @option options [#to_s]    :anon_base     ("b0")
    #   Basis for generating anonymous Nodes
    # @option options [Boolean] :resolve_uris (false)
    #   Resolve prefix and relative IRIs, otherwise, when serializing the parsed SSE
    #   as S-Expressions, use the original prefixed and relative URIs along with `base` and `prefix`
    #   definitions.
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @option options [Boolean] :progress
    #   Show progress of parser productions
    # @option options [Boolean] :debug
    #   Detailed debug output
    # @return [SPARQL::Grammar::Parser]
    def initialize(input = nil, options = {})
      @input = input
      @options = {:anon_base => "b0", :validate => false}.merge(options)

      debug("base IRI") {base_uri.inspect}
      debug("validate") {validate?.inspect}

      @vars = {}
      @nd_var_gen = "0"

      if block_given?
        case block.arity
          when 0 then instance_eval(&block)
          else block.call(self)
        end
      end
    end

    ##
    # Returns `true` if the input string is syntactically valid.
    #
    # @return [Boolean]
    def valid?
      parse
    rescue Error
      false
    end
    
    # @return [String]
    def to_sxp_bin
      @result
    end
    
    def to_s
      @result.to_sxp
    end

    alias_method :ll1_parse, :parse

    # Parse query
    #
    # The result is a SPARQL Algebra S-List. Productions return an array such as the following:
    #
    #   (prefix ((: <http://example/>))
    #     (union
    #       (bgp (triple ?s ?p ?o))
    #       (graph ?g
    #         (bgp (triple ?s ?p ?o)))))
    #
    # @param [Symbol, #to_s] prod The starting production for the parser.
    #   It may be a URI from the grammar, or a symbol representing the local_name portion of the grammar URI.
    # @return [Array]
    # @see http://www.w3.org/2001/sw/DataAccess/rq23/rq24-algebra.html
    # @see http://axel.deri.ie/sparqltutorial/ESWC2007_SPARQL_Tutorial_unit2b.pdf
    def parse(prod = START)
      ll1_parse(@input, prod.to_sym, @options.merge(:branch => BRANCH,
                                                     :first => FIRST,
                                                     :follow => FOLLOW)
      ) do |context, *data|
        loc = data.shift
        case context
        when :trace
          debug(loc, *(data.dup << {:level => 0}))
        end
      end

      # The last thing on the @prod_data stack is the result
      @result = case
      when !prod_data.is_a?(Hash)
        prod_data
      when prod_data.empty?
        nil
      when prod_data[:query]
        prod_data[:query].to_a.length == 1 ? prod_data[:query].first : prod_data[:query]
      else
        key = prod_data.keys.first
        [key] + prod_data[key]  # Creates [:key, [:triple], ...]
      end
    end

    ##
    # Returns the URI prefixes currently defined for this parser.
    #
    # @example
    #   parser.prefixes[:dc]  #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @return [Hash{Symbol => RDF::URI}]
    # @since  0.3.0
    def prefixes
      @options[:prefixes] ||= {}
    end

    ##
    # Defines the given URI prefixes for this parser.
    #
    # @example
    #   parser.prefixes = {
    #     :dc => RDF::URI('http://purl.org/dc/terms/'),
    #   }
    #
    # @param  [Hash{Symbol => RDF::URI}] prefixes
    # @return [Hash{Symbol => RDF::URI}]
    # @since  0.3.0
    def prefixes=(prefixes)
      @options[:prefixes] = prefixes
    end

    ##
    # Defines the given named URI prefix for this parser.
    #
    # @example Defining a URI prefix
    #   parser.prefix :dc, RDF::URI('http://purl.org/dc/terms/')
    #
    # @example Returning a URI prefix
    #   parser.prefix(:dc)    #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @overload prefix(name, uri)
    #   @param  [Symbol, #to_s]   name
    #   @param  [RDF::URI, #to_s] uri
    #
    # @overload prefix(name)
    #   @param  [Symbol, #to_s]   name
    #
    # @return [RDF::URI]
    def prefix(name, uri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      uri.nil? ? prefixes[name] : prefixes[name] = uri
    end

    ##
    # Returns the Base URI defined for the parser,
    # as specified or when parsing a BASE prologue element.
    #
    # @example
    #   parser.base  #=> RDF::URI('http://example.com/')
    #
    # @return [HRDF::URI]
    def base_uri
      RDF::URI(@options[:base_uri])
    end

    ##
    # Set the Base URI to use for this parser.
    #
    # @param  [RDF::URI, #to_s] uri
    #
    # @example
    #   parser.base_uri = RDF::URI('http://purl.org/dc/terms/')
    #
    # @return [RDF::URI]
    def base_uri=(uri)
      @options[:base_uri] = RDF::URI(uri)
    end

    ##
    # Returns `true` if parsed statements and values should be validated.
    #
    # @return [Boolean] `true` or `false`
    # @since  0.3.0
    def validate?
      @options[:validate]
    end

  private

    # Generate a BNode identifier
    def gen_node(id = nil)
      if @nd_var_gen
        # Use non-distinguished variables within patterns
        variable(id, false)
      else
        unless id
          id = @options[:anon_base]
          @options[:anon_base] = @options[:anon_base].succ
        end
        RDF::Node.new(id)
      end
    end

    ##
    # Return variable allocated to an ID.
    # If no ID is provided, a new variable
    # is allocated. Otherwise, any previous assignment will be used.
    #
    # The variable has a #distinguished? method applied depending on if this
    # is a disinguished or non-distinguished variable. Non-distinguished
    # variables are effectively the same as BNodes.
    # @return [RDF::Query::Variable]
    def variable(id, distinguished = true)
      id = nil if id.to_s.empty?
      
      if id
        @vars[id] ||= begin
          v = RDF::Query::Variable.new(id)
          v.distinguished = distinguished
          v
        end
      else
        unless distinguished
          # Allocate a non-distinguished variable identifier
          id = @nd_var_gen
          @nd_var_gen = id.succ
        end
        v = RDF::Query::Variable.new(id)
        v.distinguished = distinguished
        v
      end
    end

    # Create URIs
    def uri(value)
      # If we have a base URI, use that when constructing a new URI
      uri = if self.base_uri
        u = self.base_uri.join(value.to_s)
        u.lexical = "<#{value}>" unless u.to_s == value.to_s || options[:resolve_uris]
        u
      else
        RDF::URI(value)
      end

      #uri.validate! if validate? && uri.respond_to?(:validate)
      #uri.canonicalize! if canonicalize?
      #uri = RDF::URI.intern(uri) if intern?
      uri
    end

    ##
    # Progress output when debugging
    # @overload debug(node, message)
    #   @param [String] node relative location in input
    #   @param [String] message ("")
    #
    # @overload debug(message)
    #   @param [String] message ("")
    #
    # @yieldreturn [String] added to message
    def debug(*args)
      return unless @options[:debug] || RDF::Turtle.debug?
      options = args.last.is_a?(Hash) ? args.pop : {}
      debug_level = options.fetch(:level, 1)
      return unless debug_level <= DEBUG_LEVEL
      depth = options[:depth] || self.depth
      message = args.pop
      message = message.call if message.is_a?(Proc)
      args << message if message
      args << yield if block_given?
      message = "#{args.join(': ')}"
      str = "[#{@lineno}]#{' ' * depth}#{message}"
      @options[:debug] << str if @options[:debug].is_a?(Array)
      $stderr.puts(str) if RDF::Turtle.debug?
    end

  end # class Parser
end # module SPARQL::Grammar
