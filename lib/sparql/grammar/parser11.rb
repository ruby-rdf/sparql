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

    # Builtin functions
    BUILTINS = %w{
      ABS  BNODE CEIL COALESCE CONCAT
      CONTAINS DATATYPE DAY ENCODE_FOR_URI EXISTS
      FLOOR HOURS IF IRI LANGMATCHES LANG LCASE
      MD5 MINUTES MONTH NOW RAND REPLACE ROUND SECONDS
      SHA1 SHA224 SHA256 SHA384 SHA512
      STRAFTER STRBEFORE STRDT STRENDS STRLANG STRLEN STRSTARTS STRUUID STR
      TIMEZONE TZ UCASE URI UUID YEAR
      isBLANK isIRI isURI isLITERAL isNUMERIC sameTerm
    }.map {|s| s.downcase.to_sym}.freeze

    BUILTIN_RULES = [:regex, :substr, :replace, :exists, :not_exists].freeze

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
    terminal(:ANON,                 ANON) do |prod, token, input|
      add_prod_datum(:BlankNode,  bnode)
    end
    terminal(:NIL,                  NIL) do |prod, token, input|
      add_prod_datum(:NIL, RDF['nil'])
    end
    terminal(:BLANK_NODE_LABEL,     BLANK_NODE_LABEL) do |prod, token, input|
      add_prod_datum(:BlankNode, bnode(token.value[2..-1]))
    end
    terminal(:IRIREF,               IRIREF, :unescape => true) do |prod, token, input|
      begin
        add_prod_datum(:iri, iri(token.value[1..-2]))
      rescue ArgumentError => e
        raise Error, e.message
      end
    end
    terminal(:DOUBLE_POSITIVE,      DOUBLE_POSITIVE) do |prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      add_prod_datum(:literal, literal(value, :datatype => RDF::XSD.double))
    end
    terminal(:DECIMAL_POSITIVE,     DECIMAL_POSITIVE) do |prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      value = "0#{token.value}" if token.value[0,1] == "."
      add_prod_datum(:literal, literal(value, :datatype => RDF::XSD.decimal))
    end
    terminal(:INTEGER_POSITIVE,     INTEGER_POSITIVE) do |prod, token, input|
      add_prod_datum(:literal, literal(token.value, :datatype => RDF::XSD.integer))
    end
    terminal(:DOUBLE_NEGATIVE,      DOUBLE_NEGATIVE) do |prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      add_prod_datum(:literal, literal(value, :datatype => RDF::XSD.double))
    end
    terminal(:DECIMAL_NEGATIVE,     DECIMAL_NEGATIVE) do |prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      value = "0#{token.value}" if token.value[0,1] == "."
      add_prod_datum(:literal, literal(value, :datatype => RDF::XSD.decimal))
    end
    terminal(:INTEGER_NEGATIVE,     INTEGER_NEGATIVE) do |prod, token, input|
      add_prod_datum(:resource, literal(token.value, :datatype => RDF::XSD.integer))
    end
    terminal(:DOUBLE,               DOUBLE) do |prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      add_prod_datum(:literal, literal(value, :datatype => RDF::XSD.double))
    end
    terminal(:DECIMAL,              DECIMAL) do |prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      #value = "0#{token.value}" if token.value[0,1] == "."
      add_prod_datum(:literal, literal(value, :datatype => RDF::XSD.decimal))
    end
    terminal(:INTEGER,              INTEGER) do |prod, token, input|
      add_prod_datum(:literal, literal(token.value, :datatype => RDF::XSD.integer))
    end
    terminal(:LANGTAG,              LANGTAG) do |prod, token, input|
      add_prod_datum(:language, token.value[1..-1])
    end
    terminal(:PNAME_LN,             PNAME_LN, :unescape => true) do |prod, token, input|
      prefix, suffix = token.value.split(":", 2)
      add_prod_datum(:PrefixedName, ns(prefix, suffix))
    end
    terminal(:PNAME_NS,             PNAME_NS) do |prod, token, input|
      prefix = token.value[0..-2]
      # [68] PrefixedName ::= PNAME_LN | PNAME_NS
      add_prod_datum(:PrefixedName, ns(prefix, nil))
      # [4]  PrefixDecl := 'PREFIX' PNAME_NS IRI_REF";
      add_prod_datum(:prefix, prefix && prefix.to_sym)
    end
    terminal(:STRING_LITERAL_LONG1, STRING_LITERAL_LONG1, :unescape => true) do |prod, token, input|
      add_prod_datum(:string, token.value[3..-4])
    end
    terminal(:STRING_LITERAL_LONG2, STRING_LITERAL_LONG2, :unescape => true) do |prod, token, input|
      add_prod_datum(:string, token.value[3..-4])
    end
    terminal(:STRING_LITERAL1,      STRING_LITERAL1, :unescape => true) do |prod, token, input|
      add_prod_datum(:string, token.value[1..-2])
    end
    terminal(:STRING_LITERAL2,      STRING_LITERAL2, :unescape => true) do |prod, token, input|
      add_prod_datum(:string, token.value[1..-2])
    end
    terminal(:VAR1,                 VAR1) do |prod, token, input|
      add_prod_datum(:Var, variable(token.value[1..-1]))
    end
    terminal(:VAR2,                 VAR2) do |prod, token, input|
      add_prod_datum(:Var, variable(token.value[1..-1]))
    end

    # Keyword terminals
    terminal(nil, STR_EXPR, :map => STR_MAP) do |prod, token, input|
      case token.value
      when '+', '-'
        case prod
        when :_AdditiveExpression_1, :_AdditiveExpression_4, :_AdditiveExpression_5
          add_prod_datum(:AdditiveExpression, token.value)
        when :_UnaryExpression_2, :_UnaryExpression_3
          add_prod_datum(:UnaryExpression, token.value)
        else
          raise "Unexpected production #{prod} for #{token}"
        end
      when '*', '/'        then add_prod_datum(:MultiplicativeExpression, token.value)
      when '=', '!=', '<',
           '>', '<=', '>=' then add_prod_datum(:RelationalExpression, token.value)
      when '&&'            then add_prod_datum(:ConditionalAndExpression, token.value)
      when '||'            then add_prod_datum(:ConditionalOrExpression, token.value)
      when '!'             then add_prod_datum(:UnaryExpression, token.value)
      when 'a'             then add_prod_datum(:Verb, (a = RDF.type.dup; a.lexical = 'a'; a))
      when /true|false/    then add_prod_datum(:literal, RDF::Literal::Boolean.new(token.value.downcase))
      when /ASC|DESC/      then add_prod_datum(:OrderDirection, token.value.downcase.to_sym)
      when /DISTINCT|REDUCED/  then add_prod_datum(:DISTINCT_REDUCED, token.value.downcase.to_sym)
      when %r{
          ABS|BNODE|BOUND|CEIL|COALESCE|CONCAT
         |CONTAINS|DATATYPE|DAY|ENCODE_FOR_URI|EXISTS
         |FLOOR|HOURS|IF|IRI|LANGMATCHES|LANG|LCASE
         |MD5|MINUTES|MONTH|NOW|RAND|REPLACE|ROUND|SECONDS
         |SHA1|SHA224|SHA256|SHA384|SHA512
         |STRAFTER|STRBEFORE|STRDT|STRENDS|STRLANG|STRLEN|STRSTARTS|STRUUID|SUBSTR|STR
         |TIMEZONE|TZ|UCASE|URI|UUID|YEAR
         |isBLANK|isIRI|isURI|isLITERAL|isNUMERIC|sameTerm
        }x
        add_prod_datum(token.value.downcase.to_sym, token.value.downcase.to_sym)
      else
        #add_prod_datum(:string, token.value)
      end
    end

    # Productions
    # [2]  	Query	  ::=  	Prologue
    #                     ( SelectQuery | ConstructQuery | DescribeQuery | AskQuery ) ValuesClause
    production(:Query) do |input, data, callback|
      if data[:query]
        query = data[:query].first
        if data[:PrefixDecl]
          pfx = data[:PrefixDecl].shift
          data[:PrefixDecl].each {|p| pfx.merge!(p)}
          pfx.operands[1] = query
          query = pfx
        end
        query = SPARQL::Algebra::Expression[:base, data[:BaseDecl].first, query] if data[:BaseDecl]
        add_prod_datum(:query, query)
      end
    end

    # [4]  	Prologue	  ::=  	( BaseDecl | PrefixDecl )*
    production(:Prologue) do |input, data, callback|
      unless resolve_iris?
        # Only output if we're not resolving URIs internally
        add_prod_datum(:BaseDecl, data[:BaseDecl])
        add_prod_datum(:PrefixDecl, data[:PrefixDecl]) if data[:PrefixDecl]
      end
    end

    # [5]  	BaseDecl	  ::=  	'BASE' IRI_REF
    production(:BaseDecl) do |input, data, callback|
      iri = data[:iri].last
      debug("BaseDecl") {"Defined base as #{iri}"}
      self.base_uri = iri(iri)
      add_prod_datum(:BaseDecl, iri) unless resolve_iris?
    end

    # [6] PrefixDecl	  ::=  	'PREFIX' PNAME_NS IRI_REF
    production(:PrefixDecl) do |input, data, callback|
      if data[:iri]
        pfx = data[:prefix].last
        self.prefix(pfx, data[:iri].last)
        prefix_op = SPARQL::Algebra::Operator::Prefix.new([["#{pfx}:".to_sym, data[:iri].last]], [])
        add_prod_datum(:PrefixDecl, prefix_op)
      end
    end
    
    # [7]  	SelectQuery	  ::=  	SelectClause DatasetClause* WhereClause SolutionModifier
    production(:SelectQuery) do |input, data, callback|
      query = merge_modifiers(data)
      add_prod_datum :query, query
    end

    # [8]  	SubSelect	  ::=  	SelectClause WhereClause SolutionModifier

    # [9]  	SelectClause	  ::=  	'SELECT' ( 'DISTINCT' | 'REDUCED' )? ( ( Var | ( '(' Expression 'AS' Var ')' ) )+ | '*' )

    # [9.8] _SelectClause_8 ::= ( '(' Expression 'AS' Var ')' )
    production(:_SelectClause_8) do |input, data, callback|
      add_prod_datum :extend, [data[:Expression].unshift(data[:Var].first)]
      add_prod_datum :Var, data[:Var]
    end

    # [10]  	ConstructQuery	  ::=  	'CONSTRUCT'
    #                                  ( ConstructTemplate DatasetClause* WhereClause SolutionModifier | DatasetClause* 'WHERE' '{' TriplesTemplate? '}' SolutionModifier )
    production(:ConstructQuery) do |input, data, callback|
      query = merge_modifiers(data)
      template = data[:ConstructTemplate] || []
      add_prod_datum :query, SPARQL::Algebra::Expression[:construct, template, query]
    end

    # [11]  	DescribeQuery	  ::=  	'DESCRIBE' ( VarOrIri+ | '*' )
    #                             DatasetClause* WhereClause? SolutionModifier
    production(:DescribeQuery) do |input, data, callback|
      query = merge_modifiers(data)
      to_describe = data[:VarOrIri] || []
      add_prod_datum :query, SPARQL::Algebra::Expression[:describe, to_describe, query]
    end

    # [12]  	AskQuery	  ::=  	'ASK' DatasetClause* WhereClause
    production(:AskQuery) do |input, data, callback|
      query = merge_modifiers(data)
      add_prod_datum :query, SPARQL::Algebra::Expression[:ask, query]
    end

    # [14]  	DefaultGraphClause	  ::=  	SourceSelector
    production(:DefaultGraphClause) do |input, data, callback|
      add_prod_datum :dataset, data[:iri]
    end

    # [15]  	NamedGraphClause	  ::=  	'NAMED' SourceSelector
    production(:NamedGraphClause) do |input, data, callback|
      add_prod_data :dataset, data[:iri].unshift(:named)
    end

    # [18]  	SolutionModifier	  ::=  	GroupClause? HavingClause? OrderClause? LimitOffsetClauses?

    # [19]  	GroupClause	  ::=  	'GROUP' 'BY' GroupCondition+
    #production(:GroupClause) do |input, data, callback|
    #end

    # [20]  	GroupCondition	  ::=  	BuiltInCall | FunctionCall
    #                                | '(' Expression ( 'AS' Var )? ')' | Var
    #production(:GroupClause) do |input, data, callback|
    #end

    # [21]  	HavingClause	  ::=  	'HAVING' HavingCondition+
    #production(:GroupClause) do |input, data, callback|
    #end

    # [23]  	OrderClause	  ::=  	'ORDER' 'BY' OrderCondition+
    production(:OrderClause) do |input, data, callback|
      if res = data[:OrderCondition]
        res = [res] if [:asc, :desc].include?(res[0]) # Special case when there's only one condition and it's ASC (x) or DESC (x)
        add_prod_data :order, res
      end
    end

    # [24]  	OrderCondition	  ::=  	 ( ( 'ASC' | 'DESC' )
    #                                 BrackettedExpression )
    #                               | ( Constraint | Var )
    production(:OrderCondition) do |input, data, callback|
      if data[:OrderDirection]
        add_prod_datum(:OrderCondition, SPARQL::Algebra::Expression.for(data[:OrderDirection] + data[:Expression]))
      else
        add_prod_datum(:OrderCondition, data[:Constraint] || data[:Var])
      end
    end

    # [25]  	LimitOffsetClauses	  ::=  	LimitClause OffsetClause?
    #                                 | OffsetClause LimitClause?
    production(:LimitOffsetClauses) do |input, data, callback|
      if data[:limit] || data[:offset]
        limit = data[:limit] ? data[:limit].last : :_
        offset = data[:offset] ? data[:offset].last : :_
        add_prod_data :slice, offset, limit
      end
    end

    # [26]  	LimitClause	  ::=  	'LIMIT' INTEGER
    production(:LimitClause) do |input, data, callback|
      add_prod_datum(:limit, data[:literal])
    end

    # [27]  	OffsetClause	  ::=  	'OFFSET' INTEGER
    production(:OffsetClause) do |input, data, callback|
      add_prod_datum(:offset, data[:literal])
    end

    # [54]  	[55]  	GroupGraphPatternSub	  ::=  	TriplesBlock?
    #                                             ( GraphPatternNotTriples '.'? TriplesBlock? )*
    production(:GroupGraphPatternSub) do |input, data, callback|
      query_list = data[:query_list]
      debug("GroupGraphPatternSub") {"ql #{query_list.to_a.inspect}"}
      debug("GroupGraphPatternSub") {"q #{data[:query] ? data[:query].first.inspect : 'nil'}"}
            
      if query_list
        lhs = data[:query].to_a.first
        while !query_list.empty?
          rhs = query_list.shift
          # Make the right-hand-side a Join with only a single operand, if it's not already and Operator
          rhs = SPARQL::Algebra::Expression.for(:join, :placeholder, rhs) unless rhs.is_a?(SPARQL::Algebra::Operator)
          debug("GroupGraphPatternSub") {"<= q: #{rhs.inspect}"}
          debug("GroupGraphPatternSub") {"<= lhs: #{lhs ? lhs.inspect : 'nil'}"}
          lhs ||= SPARQL::Algebra::Operator::BGP.new if rhs.is_a?(SPARQL::Algebra::Operator::LeftJoin)
          if lhs
            if rhs.operand(0) == :placeholder
              rhs.operands[0] = lhs
            else
              rhs = SPARQL::Algebra::Operator::Join.new(lhs, rhs)
            end
          end
          lhs = rhs
          lhs = lhs.operand(1) if lhs.operand(0) == :placeholder
          debug("GroupGraphPatternSub(itr)") {"=> lhs: #{lhs.inspect}"}
        end
        # Trivial simplification for :join or :union of one query
        case lhs
        when SPARQL::Algebra::Operator::Join, SPARQL::Algebra::Operator::Union
          if lhs.operand(0) == :placeholder
            lhs = lhs.operand(1)
            debug("GroupGraphPatternSub(simplify)") {"=> lhs: #{lhs.inspect}"}
          end
        end
        res = lhs
      elsif data[:query]
        res = data[:query].first
      end
            
      debug("GroupGraphPatternSub(pre-filter)") {"res: #{res.inspect}"}

      if data[:filter]
        expr, query = flatten_filter(data[:filter])
        query = res || SPARQL::Algebra::Operator::BGP.new
        # query should be nil
        res = SPARQL::Algebra::Operator::Filter.new(expr, query)
      end
      add_prod_datum(:query, res)
    end

    # _GroupGraphPatternSub_2 ::= ( GraphPatternNotTriples '.'? TriplesBlock? )
    # Create a stack of GroupQuerys having a single graph element and resolve in GroupGraphPattern
    production(:_GroupGraphPatternSub_2) do |input, data, callback|
      lhs = data[:query_list]
      [data[:query]].flatten.compact.each do |rhs|
        rhs = SPARQL::Algebra::Expression.for(:join, :placeholder, rhs) if rhs.is_a?(RDF::Query)
        add_prod_data(:query_list, rhs)
      end
      add_prod_datum(:query_list, lhs) if lhs
      add_prod_datum(:filter, data[:filter])
    end

    # _GroupGraphPatternSub_3

    # [56]  	TriplesBlock	  ::=  	TriplesSameSubjectPath
    #                               ( '.' TriplesBlock? )?
    production(:TriplesBlock) do |input, data, callback|
      query = SPARQL::Algebra::Operator::BGP.new
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
    production(:GraphPatternNotTriples) do |input, data, callback|
      add_prod_datum(:filter, data[:filter])

      if data[:query]
        res = data[:query].to_a.first
        # FIXME?
        #res = SPARQL::Algebra::Expression.for(:join, :placeholder, res) unless res.is_a?(SPARQL::Algebra::Operator)
        add_prod_data(:query, res)
      end
    end

    # [58]  	OptionalGraphPattern	  ::=  	'OPTIONAL' GroupGraphPattern
    production(:OptionalGraphPattern) do |input, data, callback|
      if data[:query]
        expr = nil
        query = data[:query].first
        if query.is_a?(SPARQL::Algebra::Operator::Filter)
          # Change to expression on left-join with query element
          expr, query = query.operands
          add_prod_data(:query, SPARQL::Algebra::Expression.for(:leftjoin, :placeholder, query, expr))
        else
          add_prod_data(:query, SPARQL::Algebra::Expression.for(:leftjoin, :placeholder, query))
        end
      end
    end

    # [59]  	GraphGraphPattern	  ::=  	'GRAPH' VarOrIri GroupGraphPattern
    production(:GraphGraphPattern) do |input, data, callback|
      name = (data[:VarOrIri]).last
      bgp = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new
      if name
        add_prod_data(:query, SPARQL::Algebra::Expression.for(:graph, name, bgp))
      else
        add_prod_data(:query, bgp)
      end
    end

    # [63]  	GroupOrUnionGraphPattern	  ::=  	GroupGraphPattern
    #                                           ( 'UNION' GroupGraphPattern )*
    production(:GroupOrUnionGraphPattern) do |input, data, callback|
      res = data[:query].to_a.first
      if data[:union]
        while !data[:union].empty?
          # Join union patterns together as Union operators
          #puts "res: res: #{res}, input_prod: #{input_prod}, data[:union]: #{data[:union].first}"
          lhs = res
          rhs = data[:union].shift
          res = SPARQL::Algebra::Expression.for(:union, lhs, rhs)
        end
      end
      add_prod_datum(:query, res)
    end

    # ( 'UNION' GroupGraphPattern )*
    production(:_GroupOrUnionGraphPattern_1) do |input, data, callback|
      # Add [:union rhs] to stack based on ":union"
      add_prod_data(:union, data[:query].to_a.first)
      add_prod_data(:union, data[:union].first) if data[:union]
    end

    # [64]  	Filter	  ::=  	'FILTER' Constraint
    production(:Filter) do |input, data, callback|
      add_prod_datum(:filter, data[:Constraint])
    end

    # [65]  	Constraint	  ::=  	BrackettedExpression | BuiltInCall
    #                           | FunctionCall
    production(:Constraint) do |input, data, callback|
      if data[:Expression]
        # Resolve expression to the point it is either an atom or an s-exp
        add_prod_data(:Constraint, data[:Expression].to_a.first)
      elsif data[:BuiltInCall]
        add_prod_datum(:Constraint, data[:BuiltInCall])
      elsif data[:Function]
        add_prod_datum(:Constraint, data[:Function])
      end
    end

    # [66]  	FunctionCall	  ::=  	iri ArgList
    production(:FunctionCall) do |input, data, callback|
      add_prod_data(:Function, data[:iri] + data[:ArgList])
    end

    # [67]  	ArgList	  ::=  	NIL
    #                     | '(' 'DISTINCT'? Expression ( ',' Expression )* ')'
    production(:ArgList) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:ArgList, v)}
    end

    # [68]  	ExpressionList	  ::=  	NIL
    #                             | '(' Expression ( ',' Expression )* ')'
    production(:ExpressionList) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:ExpressionList, v)}
    end

    # [69]  	ConstructTemplate	  ::=  	'{' ConstructTriples? '}'
    start_production(:ConstructTemplate) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables
      self.nd_var_gen = false
    end
    production(:ConstructTemplate) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables
      self.nd_var_gen = "0"
      add_prod_datum(:ConstructTemplate, data[:pattern])
      add_prod_datum(:ConstructTemplate, data[:ConstructTemplate])
    end

    # [71]  	TriplesSameSubject	  ::=  	VarOrTerm PropertyListNotEmpty
    #                                 |	TriplesNode PropertyList
    production(:TriplesSameSubject) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [72]  	PropertyListNotEmpty	  ::=  	Verb ObjectList
    #                                       ( ';' ( Verb ObjectList )? )*
    start_production(:PropertyListNotEmpty) do |input, data, callback|
      subject = input[:VarOrTerm] || input[:TriplesNode] || input[:GraphNode]
      error(nil, "Expected VarOrTerm or TriplesNode or GraphNode", :production => :PropertyListNotEmpty) if validate? && !subject
      data[:Subject] = subject
    end
    production(:PropertyListNotEmpty) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [74]  	ObjectList	  ::=  	Object ( ',' Object )*
    start_production(:ObjectList) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:Subject] = prod_data[:Subject]
      error(nil, "Expected Subject", :production => :ObjectList) if !prod_data[:Subject] && validate?
      error(nil, "Expected Verb", :production => :ObjectList) if !prod_data[:Verb] && validate?
      data[:Subject] = prod_data[:Subject]
      data[:Verb] = prod_data[:Verb].to_a.last
    end
    production(:ObjectList) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [75]  	Object	  ::=  	GraphNode
    production(:Object) do |input, data, callback|
      object = data[:VarOrTerm] || data[:TriplesNode] || data[:GraphNode]
      if object
        add_pattern(:Object, :subject => prod_data[:Subject], :predicate => prod_data[:Verb], :object => object)
        add_prod_datum(:pattern, data[:pattern])
      end
    end

    # [76]  	Verb	  ::=  	VarOrIri | 'a'
    production(:Verb) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:Verb, v)}
    end

    # [78]  	PropertyListNotEmptyPath	  ::=  	( VerbPath | VerbSimple ) ObjectList ( ';' ( ( VerbPath | VerbSimple ) ObjectList )? )*
    start_production(:PropertyListNotEmptyPath) do |input, data, callback|
      subject = input[:VarOrTerm]
      error(nil, "Expected VarOrTerm", :production => ::PropertyListNotEmptyPath) if validate? && !subject
      data[:Subject] = subject
    end
    production(:PropertyListNotEmptyPath) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [80]  	VerbPath	  ::=  	Path
    production(:VerbPath) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:Verb, v)}
    end

    # [81]  	VerbSimple	  ::=  	Var
    production(:VerbSimple) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:Verb, v)}
    end

    # [92]  	TriplesNode	  ::=  	Collection |	BlankNodePropertyList
    start_production(:TriplesNode) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:TriplesNode] = bnode
    end
    production(:TriplesNode) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:TriplesNode, data[:TriplesNode])
    end

    # [94]  	Collection	  ::=  	'(' GraphNode+ ')'
    start_production(:Collection) do |input, data, callback|
      # Tells the TriplesNode production to collect and not generate statements
      data[:Collection] = prod_data[:TriplesNode]
    end
    production(:Collection) do |input, data, callback|
      expand_collection(data)
    end

    # [95]  	GraphNode	  ::=  	VarOrTerm |	TriplesNode
    production(:GraphNode) do |input, data, callback|
      term = data[:VarOrTerm] || data[:TriplesNode]
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:GraphNode, term)
    end

    # [96]  	VarOrTerm	  ::=  	Var | GraphTerm
    production(:VarOrTerm) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:VarOrTerm, v)}
    end

    # [97]  	VarOrIri	  ::=  	Var | iri
    production(:VarOrIri) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:VarOrIri, v)}
    end

    # [99]  	GraphTerm	  ::=  	iri |	RDFLiteral |	NumericLiteral
    #                         |	BooleanLiteral |	BlankNode |	NIL
    production(:GraphTerm) do |input, data, callback|
      add_prod_datum(:GraphTerm,
                      data[:iri] ||
                      data[:literal] ||
                      data[:BlankNode] ||
                      data[:NIL])
    end

    # [100]  	Expression	  ::=  	ConditionalOrExpression
    production(:Expression) do |input, data, callback|
      add_prod_datum(:Expression, data[:Expression])
    end

    # [101]  	ConditionalOrExpression	  ::=  	ConditionalAndExpression
    #                                         ( '||' ConditionalAndExpression )*
    production(:ConditionalOrExpression) do |input, data, callback|
      add_operator_expressions(:_OR, data)
    end

    # ( '||' ConditionalAndExpression )*
    production(:_ConditionalOrExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:ConditionalOrExpression, :_OR, data)
    end

    # [102]  	ConditionalAndExpression	  ::=  	ValueLogical ( '&&' ValueLogical )*
    production(:ConditionalAndExpression) do |input, data, callback|
      add_operator_expressions(:_AND, data)
    end

    # ( '||' ConditionalAndExpression )*
    production(:_ConditionalAndExpression_1) do |input, data, callback|
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
    production(:RelationalExpression) do |input, data, callback|
      if data[:_Compare_Numeric]
        add_prod_datum(:Expression, SPARQL::Algebra::Expression.for(data[:_Compare_Numeric].insert(1, *data[:Expression])))
      else
        # NumericExpression with no comparitor
        add_prod_datum(:Expression, data[:Expression])
      end
    end

    # ( '=' NumericExpression | '!=' NumericExpression | ... )?
    production(:_RelationalExpression_1) do |input, data, callback|
      if data[:RelationalExpression]
        add_prod_datum(:_Compare_Numeric, data[:RelationalExpression] + data[:Expression])
      end
    end

    # [106]  	AdditiveExpression	  ::=  	MultiplicativeExpression
    #                                     ( '+' MultiplicativeExpression
    #                                     | '-' MultiplicativeExpression
    #                                     | ( NumericLiteralPositive | NumericLiteralNegative )
    #                                       ( ( '*' UnaryExpression )
    #                                     | ( '/' UnaryExpression ) )?
    #                                     )*
    production(:AdditiveExpression) do |input, data, callback|
      add_operator_expressions(:_Add_Sub, data)
    end

    # ( '+' MultiplicativeExpression
    # | '-' MultiplicativeExpression
    # | ( NumericLiteralPositive | NumericLiteralNegative )
    #   ( ( '*' UnaryExpression )
    # | ( '/' UnaryExpression ) )?
    # )*
    production(:_AdditiveExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:AdditiveExpression, :_Add_Sub, data)
    end

    # | ( NumericLiteralPositive | NumericLiteralNegative )
    production(:_AdditiveExpression_7) do |input, data, callback|
      val = data[:literal].first.to_s
      op, val = val[0,1], val[1..-1]
      add_prod_datum(:AdditiveExpression, op)
      add_prod_datum(:Expression, data[:literal])
    end

    # [107]  	MultiplicativeExpression	  ::=  	UnaryExpression
    #                                           ( '*' UnaryExpression
    #                                           | '/' UnaryExpression )*
    production(:MultiplicativeExpression) do |input, data, callback|
      add_operator_expressions(:_Mul_Div, data)
    end

    # ( '*' UnaryExpression
    # | '/' UnaryExpression )*
    production(:_MultiplicativeExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:MultiplicativeExpression, :_Mul_Div, data)
    end

    # [108]  	UnaryExpression	  ::=  	  '!' PrimaryExpression 
    #                                 |	'+' PrimaryExpression 
    #                                 |	'-' PrimaryExpression 
    #                                 |	PrimaryExpression
    production(:UnaryExpression) do |input, data, callback|
      case data[:UnaryExpression]
      when ["!"]
        add_prod_datum(:Expression, SPARQL::Algebra::Expression[:not, data[:Expression].first])
      when ["-"]
        e = data[:Expression].first
        if e.is_a?(RDF::Literal::Numeric)
          add_prod_datum(:Expression, -e) # Simple optimization to match ARQ generation
        else
          add_prod_datum(:Expression, SPARQL::Algebra::Expression[:minus, e])
        end
      else
        add_prod_datum(:Expression, data[:Expression])
      end
    end

    # [109]  	PrimaryExpression	  ::=  	BrackettedExpression | BuiltInCall
    #                                 | iriOrFunction | RDFLiteral
    #                                 | NumericLiteral | BooleanLiteral
    #                                 | Var | Aggregate
    production(:PrimaryExpression) do |input, data, callback|
      if data[:Expression]
        add_prod_datum(:Expression, data[:Expression])
      elsif data[:BuiltInCall]
        add_prod_datum(:Expression, data[:BuiltInCall])
      elsif data[:iri]
        add_prod_datum(:Expression, data[:iri])
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
    production(:BuiltInCall) do |input, data, callback|
      if builtin = data.keys.detect {|k| BUILTINS.include?(k)}
        add_prod_datum(:BuiltInCall,
          SPARQL::Algebra::Expression.for(
            (data[:ExpressionList] || data[:Expression] || []).
            unshift(builtin)))
      elsif builtin_rule = data.keys.detect {|k| BUILTIN_RULES.include?(k)}
        add_prod_datum(:BuiltInCall, SPARQL::Algebra::Expression.for(data[builtin_rule].unshift(builtin_rule)))
      elsif data[:bound]
        add_prod_datum(:BuiltInCall, SPARQL::Algebra::Expression.for(data[:Var].unshift(:bound)))
      elsif data[:BuiltInCall]
        add_prod_datum(:BuiltInCall, SPARQL::Algebra::Expression.for(data[:BuiltInCall] + data[:Expression]))
      end
    end

    # [112]  	RegexExpression	  ::=  	'REGEX' '(' Expression ',' Expression
    #                                 ( ',' Expression )? ')'
    production(:RegexExpression) do |input, data, callback|
      add_prod_datum(:regex, data[:Expression])
    end

    # [123]  	SubstringExpression	  ::=  	'SUBSTR'
    #                                     '(' Expression ',' Expression
    #                                     ( ',' Expression )? ')'
    production(:SubstringExpression) do |input, data, callback|
      add_prod_datum(:substr, data[:Expression])
    end

    # [124] StrReplaceExpression    ::= 'REPLACE'
    #                                   '(' Expression ','
    #                                   Expression ',' Expression
    #                                   ( ',' Expression )? ')'
    production(:StrReplaceExpression) do |input, data, callback|
      add_prod_datum(:replace, data[:Expression])
    end

    # [114]  	ExistsFunc	  ::=  	'EXISTS' GroupGraphPattern
    production(:ExistsFunc) do |input, data, callback|
      add_prod_datum(:exists, data[:query])
    end

    # [115]  	NotExistsFunc	  ::=  	'NOT' 'EXISTS' GroupGraphPattern
    production(:NotExistsFunc) do |input, data, callback|
      add_prod_datum(:not_exists, data[:query])
    end

    # [117]  	iriOrFunction	  ::=  	iri ArgList?
    production(:iriOrFunction) do |input, data, callback|
      if data.has_key?(:ArgList)
        # Function is (func arg1 arg2 ...)
        add_prod_data(:Function, data[:iri] + data[:ArgList])
      else
        add_prod_datum(:iri, data[:iri])
      end
    end

    # [118]  	RDFLiteral	  ::=  	String ( LANGTAG | ( '^^' iri ) )?
    production(:RDFLiteral) do |input, data, callback|
      if data[:string]
        lit = data.dup
        str = lit.delete(:string).last 
        lit[:datatype] = lit.delete(:iri).last if lit[:iri]
        lit[:language] = lit.delete(:language).last.downcase if lit[:language]
        add_prod_datum(:literal, RDF::Literal.new(str, lit)) if str
      end
    end

    # [121]  	NumericLiteralPositive	  ::=  	INTEGER_POSITIVE
    #                                       |	DECIMAL_POSITIVE
    #                                       |	DOUBLE_POSITIVE
    production(:NumericLiteralPositive) do |input, data, callback|
      num = data.values.flatten.last
      add_prod_datum(:literal, num)

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [122]  	NumericLiteralNegative	  ::=  	INTEGER_NEGATIVE
    #                                       |	DECIMAL_NEGATIVE
    #                                       |	DOUBLE_NEGATIVE
    production(:NumericLiteralNegative) do |input, data, callback|
      num = data.values.flatten.last
      add_prod_datum(:literal, num)

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [126]  	PrefixedName	  ::=  	PNAME_LN | PNAME_NS
    production(:PrefixedName) do |input, data, callback|
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
    # @option options [Boolean] :resolve_iris (false)
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
      @input = input.to_s.dup
      @input.force_encoding(Encoding::UTF_8) if @input.respond_to?(:force_encoding) 
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
      ) {}

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

    private
    ##
    # Returns the URI prefixes currently defined for this parser.
    #
    # @example
    #   prefixes[:dc]  #=> RDF::URI('http://purl.org/dc/terms/')
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
    #   prefixes = {
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
    #   prefix :dc, RDF::URI('http://purl.org/dc/terms/')
    #
    # @example Returning a URI prefix
    #   prefix(:dc)    #=> RDF::URI('http://purl.org/dc/terms/')
    #
    # @overload prefix(name, uri)
    #   @param  [Symbol, #to_s]   name
    #   @param  [RDF::URI, #to_s] uri
    #
    # @overload prefix(name)
    #   @param  [Symbol, #to_s]   name
    #
    # @return [RDF::URI]
    def prefix(name, iri = nil)
      name = name.to_s.empty? ? nil : (name.respond_to?(:to_sym) ? name.to_sym : name.to_s.to_sym)
      iri.nil? ? prefixes[name] : prefixes[name] = iri
    end

    ##
    # Returns the Base URI defined for the parser,
    # as specified or when parsing a BASE prologue element.
    #
    # @example
    #   base  #=> RDF::URI('http://example.com/')
    #
    # @return [HRDF::URI]
    def base_uri
      RDF::URI(@options[:base_uri])
    end

    ##
    # Set the Base URI to use for this parser.
    #
    # @param  [RDF::URI, #to_s] iri
    #
    # @example
    #   base_uri = RDF::URI('http://purl.org/dc/terms/')
    #
    # @return [RDF::URI]
    def base_uri=(iri)
      @options[:base_uri] = RDF::URI(iri)
    end

    ##
    # Returns `true` if parsed statements and values should be validated.
    #
    # @return [Boolean] `true` or `false`
    # @since  0.3.0
    def resolve_iris?
      @options[:resolve_iris]
    end

    ##
    # Returns `true` when resolving IRIs, otherwise BASE and PREFIX are retained in the output algebra.
    #
    # @return [Boolean] `true` or `false`
    # @since  1.0.3
    def validate?
      @options[:validate]
    end

    # Used for generating BNode labels
    attr_accessor :nd_var_gen

    # Generate a BNode identifier
    def bnode(id = nil)
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
    def iri(value)
      # If we have a base URI, use that when constructing a new URI
      iri = if base_uri
        u = base_uri.join(value.to_s)
        u.lexical = "<#{value}>" unless u.to_s == value.to_s || resolve_iris?
        u
      else
        RDF::URI(value)
      end

      #iri.validate! if validate? && iri.respond_to?(:validate)
      #iri = RDF::URI.intern(iri) if intern?
      iri
    end

    def ns(prefix, suffix)
      base = prefix(prefix).to_s
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      debug {"ns(#{prefix.inspect}): base: '#{base}', suffix: '#{suffix}'"}
      iri = iri(base + suffix.to_s)
      # Cause URI to be serialized as a lexical
      iri.lexical = "#{prefix}:#{suffix}" unless resolve_iris?
      iri
    end
    
    # Create a literal
    def literal(value, options = {})
      options = options.dup
      # Internal representation is to not use xsd:string, although it could arguably go the other way.
      options.delete(:datatype) if options[:datatype] == RDF::XSD.string
      debug("literal") do
        "value: #{value.inspect}, " +
        "options: #{options.inspect}, " +
        "validate: #{validate?.inspect}, "
      end
      RDF::Literal.new(value, options.merge(:validate => validate?))
    end

    # Take collection of objects and create RDF Collection using rdf:first, rdf:rest and rdf:nil
    # @param [Hash] data Production Data
    def expand_collection(data)
      # Add any triples generated from deeper productions
      add_prod_datum(:pattern, data[:pattern])
      
      # Create list items for each element in data[:GraphNode]
      first = col = data[:Collection]
      list = data[:GraphNode].to_a.flatten.compact
      last = list.pop

      list.each do |r|
        add_pattern(:Collection, :subject => first, :predicate => RDF["first"], :object => r)
        rest = bnode()
        add_pattern(:Collection, :subject => first, :predicate => RDF["rest"], :object => rest)
        first = rest
      end
      
      if last
        add_pattern(:Collection, :subject => first, :predicate => RDF["first"], :object => last)
      end
      add_pattern(:Collection, :subject => first, :predicate => RDF["rest"], :object => RDF["nil"])
    end

    # add a pattern
    #
    # @param [String] production Production generating pattern
    # @param [Hash{Symbol => Object}] options
    def add_pattern(production, options)
      progress(production, "add_pattern: #{options.inspect}")
      progress(production, "[:pattern, #{options[:subject]}, #{options[:predicate]}, #{options[:object]}]")
      triple = {}
      options.each_pair do |r, v|
        if v.is_a?(Array) && v.flatten.length == 1
          v = v.flatten.first
        end
        if validate? && !v.is_a?(RDF::Term)
          error("add_pattern", "Expected #{r} to be a resource, but it was #{v.inspect}",
            :production => production)
        end
        triple[r] = v
      end
      add_prod_datum(:pattern, RDF::Query::Pattern.new(triple))
    end

    # Flatten a Data in form of :filter => [op+ bgp?], without a query into filter and query creating exprlist, if necessary
    # @return [Array[:expr, query]]
    def flatten_filter(data)
      query = data.pop if data.last.respond_to?(:execute)
      expr = data.length > 1 ? SPARQL::Algebra::Operator::Exprlist.new(*data) : data.first
      [expr, query]
    end
    
    # Merge query modifiers, datasets, and projections
    def merge_modifiers(data)
      query = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new
      
      # Add datasets and modifiers in order
      query = SPARQL::Algebra::Expression[:extend, data[:extend], query] if data[:extend]

      query = SPARQL::Algebra::Expression[:order, data[:order].first, query] if data[:order]

      query = SPARQL::Algebra::Expression[:project, data[:Var], query] if data[:Var]

      query = SPARQL::Algebra::Expression[data[:DISTINCT_REDUCED].first, query] if data[:DISTINCT_REDUCED]

      query = SPARQL::Algebra::Expression[:slice, data[:slice][0], data[:slice][1], query] if data[:slice]
      
      query = SPARQL::Algebra::Expression[:dataset, data[:dataset], query] if data[:dataset]
      
      query
    end

    # Add joined expressions in for prod1 (op prod2)* to form (op (op 1 2) 3)
    def add_operator_expressions(production, data)
      # Iterate through expression to create binary operations
      res = data[:Expression]
      while data[production] && !data[production].empty?
        res = SPARQL::Algebra::Expression[data[production].shift + res + data[production].shift]
      end
      add_prod_datum(:Expression, res)
    end

    # Accumulate joined expressions in for prod1 (op prod2)* to form (op (op 1 2) 3)
    def accumulate_operator_expressions(operator, production, data)
      if data[operator]
        # Add [op data] to stack based on "production"
        add_prod_datum(production, [data[operator], data[:Expression]])
        # Add previous [op data] information
        add_prod_datum(production, data[production])
      else
        # No operator, forward :Expression
        add_prod_datum(:Expression, data[:Expression])
      end
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
      return unless @options[:debug]
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
      case @options[:debug]
      when Array
        options[:debug] << str
      else
        $stderr.puts str
      end
    end

  end # class Parser
end # module SPARQL::Grammar
