require 'ebnf'
require 'ebnf/ll1/parser'
require 'sparql/grammar/meta'

module SPARQL::Grammar
  ##
  # A parser for the SPARQL 1.1 grammar.
  #
  # @see http://www.w3.org/TR/sparql11-query/#grammar
  # @see http://en.wikipedia.org/wiki/LR_parser
  class Parser
    include SPARQL::Grammar::Meta
    include SPARQL::Grammar::Terminals
    include EBNF::LL1::Parser

    # Builtin functions
    BUILTINS = %w{
      ABS  BNODE CEIL COALESCE CONCAT
      CONTAINS DATATYPE DAY ENCODE_FOR_URI
      FLOOR HOURS IF IRI LANGMATCHES LANG LCASE
      MD5 MINUTES MONTH NOW RAND ROUND SECONDS
      SHA1 SHA224 SHA256 SHA384 SHA512
      STRAFTER STRBEFORE STRDT STRENDS STRLANG STRLEN STRSTARTS STRUUID STR
      TIMEZONE TZ UCASE URI UUID YEAR
      isBLANK isIRI isURI isLITERAL isNUMERIC sameTerm
    }.map {|s| s.downcase.to_sym}.freeze

    BUILTIN_RULES = [:aggregate, :regex, :substr, :replace, :exists, :notexists].freeze

    AGGREGATE_RULES = [:count, :sum, :min, :max, :avg, :sample, :group_concat]
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
    # The internal representation of the result using hierarchy of RDF objects and SPARQL::Algebra::Operator
    # objects.
    # @return [Array]
    # @see http://sparql.rubyforge.org/algebra
    attr_accessor :result

    # Terminals passed to lexer. Order matters!
    terminal(:ANON,                 ANON) do |prod, token, input|
      input[:BlankNode] = bnode
    end
    terminal(:NIL,                  NIL) do |prod, token, input|
      input[:NIL] = RDF['nil']
    end
    terminal(:BLANK_NODE_LABEL,     BLANK_NODE_LABEL) do |prod, token, input|
      input[:BlankNode] = bnode(token.value[2..-1])
    end
    terminal(:IRIREF,               IRIREF, unescape: true) do |prod, token, input|
      begin
        input[:iri] = iri(token.value[1..-2])
      rescue ArgumentError => e
        raise Error, e.message
      end
    end
    terminal(:DOUBLE_POSITIVE,      DOUBLE_POSITIVE) do |prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      input[:literal] = literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL_POSITIVE,     DECIMAL_POSITIVE) do |prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      value = "0#{token.value}" if token.value[0,1] == "."
      input[:literal] = literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER_POSITIVE,     INTEGER_POSITIVE) do |prod, token, input|
      input[:literal] = literal(token.value, datatype: RDF::XSD.integer)
    end
    terminal(:DOUBLE_NEGATIVE,      DOUBLE_NEGATIVE) do |prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      input[:literal] = literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL_NEGATIVE,     DECIMAL_NEGATIVE) do |prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      value = "0#{token.value}" if token.value[0,1] == "."
      input[:literal] = literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER_NEGATIVE,     INTEGER_NEGATIVE) do |prod, token, input|
      input[:literal] = literal(token.value, datatype: RDF::XSD.integer)
    end
    terminal(:DOUBLE,               DOUBLE) do |prod, token, input|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = token.value.sub(/\.([eE])/, '.0\1')
      input[:literal] = literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL,              DECIMAL) do |prod, token, input|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = token.value
      #value = "0#{token.value}" if token.value[0,1] == "."
      input[:literal] = literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER,              INTEGER) do |prod, token, input|
      input[:literal] = literal(token.value, datatype: RDF::XSD.integer)
    end
    terminal(:LANGTAG,              LANGTAG) do |prod, token, input|
      add_prod_datum(:language, token.value[1..-1])
    end
    terminal(:PNAME_LN,             PNAME_LN, unescape: true) do |prod, token, input|
      prefix, suffix = token.value.split(":", 2)
      input[:iri] = ns(prefix, suffix)
    end
    terminal(:PNAME_NS,             PNAME_NS) do |prod, token, input|
      prefix = token.value[0..-2]
      # [68] PrefixedName ::= PNAME_LN | PNAME_NS
      input[:iri] = ns(prefix, nil)
      input[:prefix] = prefix && prefix.to_sym
    end
    terminal(:STRING_LITERAL_LONG1, STRING_LITERAL_LONG1, unescape: true) do |prod, token, input|
      input[:string] = token.value[3..-4]
    end
    terminal(:STRING_LITERAL_LONG2, STRING_LITERAL_LONG2, unescape: true) do |prod, token, input|
      input[:string] = token.value[3..-4]
    end
    terminal(:STRING_LITERAL1,      STRING_LITERAL1, unescape: true) do |prod, token, input|
      input[:string] = token.value[1..-2]
    end
    terminal(:STRING_LITERAL2,      STRING_LITERAL2, unescape: true) do |prod, token, input|
      input[:string] = token.value[1..-2]
    end
    terminal(:VAR1,                 VAR1) do |prod, token, input|
      add_prod_datum(:Var, variable(token.value[1..-1]))
    end
    terminal(:VAR2,                 VAR2) do |prod, token, input|
      add_prod_datum(:Var, variable(token.value[1..-1]))
    end

    # Keyword terminals
    terminal(nil, STR_EXPR, map: STR_MAP) do |prod, token, input|
      case token.value
      when '+', '-'
        case prod
        when :_AdditiveExpression_1, :_AdditiveExpression_4, :_AdditiveExpression_5
          add_prod_datum(:AdditiveExpression, token.value)
        when :_UnaryExpression_2, :_UnaryExpression_3
          add_prod_datum(:UnaryExpression, token.value)
        when :PathMod
          add_prod_datum(:PathMod, token.value)
        else
          raise "Unexpected production #{prod} for #{token}"
        end
      when '?'             then add_prod_datum(:PathMod, token.value)
      when '^'             then input[:reverse] = token.value
      when '*', '/'        then add_prod_datum(:MultiplicativeExpression, token.value)
      when '=', '!=', '<',
           '>', '<=', '>=' then add_prod_datum(:RelationalExpression, token.value)
      when '&&'            then add_prod_datum(:ConditionalAndExpression, token.value)
      when '||'            then add_prod_datum(:ConditionalOrExpression, token.value)
      when '!'             then add_prod_datum(:UnaryExpression, token.value)
      when 'a'             then input[:Verb] = (a = RDF.type.dup; a.lexical = 'a'; a)
      when /true|false/    then input[:literal] = RDF::Literal::Boolean.new(token.value.downcase)
      when /ASC|DESC/      then input[:OrderDirection] = token.value.downcase.to_sym
      when /DISTINCT|REDUCED/  then input[:DISTINCT_REDUCED] = token.value.downcase.to_sym
      when %r{
          ABS|ALL|AVG|BNODE|BOUND|CEIL|COALESCE|CONCAT
         |CONTAINS|COUNT|DATATYPE|DAY|DEFAULT|ENCODE_FOR_URI|EXISTS
         |FLOOR|HOURS|IF|GRAPH|GROUP_CONCAT|IRI|LANGMATCHES|LANG|LCASE
         |MAX|MD5|MINUTES|MIN|MONTH|NAMED|NOW|RAND|REPLACE|ROUND|SAMPLE|SECONDS|SEPARATOR
         |SHA1|SHA224|SHA256|SHA384|SHA512|SILENT
         |STRAFTER|STRBEFORE|STRDT|STRENDS|STRLANG|STRLEN|STRSTARTS|STRUUID|SUBSTR|STR|SUM
         |TIMEZONE|TZ|UCASE|UNDEF|URI|UUID|YEAR
         |isBLANK|isIRI|isURI|isLITERAL|isNUMERIC|sameTerm
        }x
        add_prod_datum(token.value.downcase.to_sym, token.value.downcase.to_sym)
      else
        #add_prod_datum(:string, token.value)
      end
    end

    # Productions
    # [2]  	Query	  ::=  	Prologue
    #                     ( SelectQuery | ConstructQuery | DescribeQuery | AskQuery )
    production(:Query) do |input, data, callback|
      query = data[:query].first

      # Add prefix
      if data[:PrefixDecl]
        pfx = data[:PrefixDecl].shift
        data[:PrefixDecl].each {|p| pfx.merge!(p)}
        pfx.operands[1] = query
        query = pfx
      end

      # Add base
      query = SPARQL::Algebra::Expression[:base, data[:BaseDecl].first, query] if data[:BaseDecl]

      add_prod_datum(:query, query)
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
      iri = data[:iri]
      debug("BaseDecl") {"Defined base as #{iri}"}
      self.base_uri = iri(iri)
      add_prod_datum(:BaseDecl, iri) unless resolve_iris?
    end

    # [6] PrefixDecl	  ::=  	'PREFIX' PNAME_NS IRI_REF
    production(:PrefixDecl) do |input, data, callback|
      if data[:iri]
        pfx = data[:prefix]
        self.prefix(pfx, data[:iri])
        prefix_op = SPARQL::Algebra::Operator::Prefix.new([["#{pfx}:".to_sym, data[:iri]]], [])
        add_prod_datum(:PrefixDecl, prefix_op)
      end
    end

    # [7]  	SelectQuery	  ::=  	SelectClause DatasetClause* WhereClause SolutionModifier
    production(:SelectQuery) do |input, data, callback|
      query = merge_modifiers(data)
      add_prod_datum :query, query
    end

    # [8]  	SubSelect	  ::=  	SelectClause WhereClause SolutionModifier
    production(:SubSelect) do |input, data, callback|
      query = merge_modifiers(data)
      add_prod_datum :query, query
    end

    # [9]  	SelectClause	  ::=  	'SELECT' ( 'DISTINCT' | 'REDUCED' )? ( ( Var | ( '(' Expression 'AS' Var ')' ) )+ | '*' )

    # [9.8] _SelectClause_8 ::= ( '(' Expression 'AS' Var ')' )
    production(:_SelectClause_8) do |input, data, callback|
      add_prod_datum :extend, [data[:Expression].unshift(data[:Var].first)]
    end

    # [10]  ConstructQuery ::= 'CONSTRUCT'
    #                          ( ConstructTemplate
    #                            DatasetClause*
    #                            WhereClause
    #                            SolutionModifier | DatasetClause*
    #                            'WHERE' '{' TriplesTemplate? '}'
    #                            SolutionModifier
    #                          )
    production(:ConstructQuery) do |input, data, callback|
      data[:query] ||= [SPARQL::Algebra::Operator::BGP.new(*data[:pattern])]
      query = merge_modifiers(data)
      template = data[:ConstructTemplate] || data[:pattern] || []
      add_prod_datum :query, SPARQL::Algebra::Expression[:construct, template, query]
    end

    # [11]  	DescribeQuery	  ::=  	'DESCRIBE' ( VarOrIri+ | '*' )
    #                             DatasetClause* WhereClause? SolutionModifier
    production(:DescribeQuery) do |input, data, callback|
      query = merge_modifiers(data)
      to_describe = Array(data[:VarOrIri])
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
      add_prod_data :dataset, [:named, data[:iri]]
    end

    # [18]  	SolutionModifier	  ::=  	GroupClause? HavingClause? OrderClause? LimitOffsetClauses?

    # [19]  	GroupClause	  ::=  	'GROUP' 'BY' GroupCondition+
    production(:GroupClause) do |input, data, callback|
      add_prod_data :group, data[:GroupCondition]
    end

    # [20]  	GroupCondition	  ::=  	BuiltInCall | FunctionCall
    #                                | '(' Expression ( 'AS' Var )? ')' | Var
    production(:GroupCondition) do |input, data, callback|
      add_prod_datum :GroupCondition, data.values.first
    end

    # _GroupCondition_1 ::= '(' Expression ( 'AS' Var )? ')'
    production(:_GroupCondition_1) do |input, data, callback|
      cond = if data[:Var]
        [data[:Expression].unshift(data[:Var].first)]
      else
        data[:Expression]
      end
      add_prod_datum(:GroupCondition, cond)
    end

    # [21]  	HavingClause	  ::=  	'HAVING' HavingCondition+
    production(:HavingClause) do |input, data, callback|
      add_prod_datum(:having, data[:Constraint])
    end

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
        add_prod_datum(:OrderCondition, SPARQL::Algebra::Expression(data[:OrderDirection], *data[:Expression]))
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

    # [28]  ValuesClause	          ::= ( 'VALUES' DataBlock )?
    production(:ValuesClause) do |input, data, callback|
      debug("ValuesClause") {"vars: #{data[:Var].inspect}, row: #{data[:row].inspect}"}
      if data[:row]
        add_prod_datum :ValuesClause, SPARQL::Algebra::Expression.for(:table,
          Array(data[:Var]).unshift(:vars),
          *data[:row]
        )
      else
        add_prod_datum :ValuesClause, SPARQL::Algebra::Expression.for(:table, :empty)
      end
    end

    # [29]	Update	::=	Prologue (Update1 (";" Update)? )?
    production(:Update) do |input, data, callback|
      update = data[:update] || SPARQL::Algebra::Expression(:update)

      # Add prefix
      if data[:PrefixDecl]
        pfx = data[:PrefixDecl].shift
        data[:PrefixDecl].each {|p| pfx.merge!(p)}
        pfx.operands[1] = update
        update = pfx
      end

      # Add base
      update = SPARQL::Algebra::Expression[:base, data[:BaseDecl].first, update] if data[:BaseDecl]

      # Don't use update operator twice, if we can help it
      input[:update] = update
    end
    production(:_Update_3) do |input, data, callback|
      if data[:update]
        if input[:update].is_a?(SPARQL::Algebra::Operator::Update)
          # Append operands
          input[:update] = SPARQL::Algebra::Expression(:update, *(input[:update].operands + data[:update].operands))
        else
          add_prod_datum(:update, data[:update])
        end
      end
    end

    # [30]	Update1	::=	Load | Clear | Drop | Add | Move | Copy | Create | InsertData | DeleteData | DeleteWhere | Modify
    production(:Update1) do |input, data, callback|
      input[:update] = SPARQL::Algebra::Expression.for(:update, data[:update_op])
    end

    # [31]	Load	::=	"LOAD" "SILENT"? iri ("INTO" GraphRef)?
    production(:Load) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args << data[:iri]
      args << data[:into] if data[:into]
      input[:update_op] = SPARQL::Algebra::Expression(:load, *args)
    end
    production(:_Load_2) do |input, data, callback|
      input[:into] = data[:iri]
    end

    # [32]	Clear	::=	"CLEAR" "SILENT"? GraphRefAll
    production(:Clear) do |input, data, callback|
      args = []
      %w(silent default named all).map(&:to_sym).each do |s|
        args << s if data[s]
      end
      args += Array(data[:iri])
      input[:update_op] = SPARQL::Algebra::Expression(:clear, *args)
    end

    # [33]	Drop	::=	"DROP" "SILENT"? GraphRefAll
    production(:Drop) do |input, data, callback|
      args = []
      %w(silent default named all).map(&:to_sym).each do |s|
        args << s if data[s]
      end
      args += Array(data[:iri])
      input[:update_op] = SPARQL::Algebra::Expression(:drop, *args)
    end

    # [34]	Create	::=	"CREATE" "SILENT"? GraphRef
    production(:Create) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args += Array(data[:iri])
      input[:update_op] = SPARQL::Algebra::Expression(:create, *args)
    end

    # [35]	Add	::=	"ADD" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    production(:Add) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args += data[:GraphOrDefault]
      input[:update_op] = SPARQL::Algebra::Expression(:add, *args)
    end

    # [36]	Move	::=	"MOVE" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    production(:Move) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args += data[:GraphOrDefault]
      input[:update_op] = SPARQL::Algebra::Expression(:move, *args)
    end

    # [37]	Copy	::=	"COPY" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    production(:Copy) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args += data[:GraphOrDefault]
      input[:update_op] = SPARQL::Algebra::Expression(:copy, *args)
    end

    # [38]	InsertData	::=	"INSERT DATA" QuadData
    start_production(:InsertData) do |input, data, callback|
      # Freeze existing bnodes, so that if an attempt is made to re-use such a node, and error is raised
      self.freeze_bnodes
    end
    production(:InsertData) do |input, data, callback|
      input[:update_op] = SPARQL::Algebra::Expression(:insertData, data[:pattern])
    end

    # [39]	DeleteData	::=	"DELETE DATA" QuadData
    start_production(:DeleteData) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
      self.gen_bnodes
    end
    production(:DeleteData) do |input, data, callback|
      raise Error, "DeleteData contains BNode operands: #{data[:pattern].to_sse}" if Array(data[:pattern]).any?(&:node?)
      input[:update_op] = SPARQL::Algebra::Expression(:deleteData, Array(data[:pattern]))
    end

    # [40]	DeleteWhere	::=	"DELETE WHERE" QuadPattern
    start_production(:DeleteWhere) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
      self.gen_bnodes
    end
    production(:DeleteWhere) do |input, data, callback|
      raise Error, "DeleteWhere contains BNode operands: #{data[:pattern].to_sse}" if Array(data[:pattern]).any?(&:node?)
      self.gen_bnodes(false)
      input[:update_op] = SPARQL::Algebra::Expression(:deleteWhere, Array(data[:pattern]))
    end

    # [41]	Modify	::=	("WITH" iri)? ( DeleteClause InsertClause? | InsertClause) UsingClause* "WHERE" GroupGraphPattern
    start_production(:Modify) do |input, data, callback|
      self.clear_bnode_cache
    end
    production(:Modify) do |input, data, callback|
      query = data[:query].first if data[:query]
      query = SPARQL::Algebra::Expression.for(:using, data[:using], query) if data[:using]
      operands = [query, data[:delete], data[:insert]].compact
      operands = [SPARQL::Algebra::Expression.for(:with, data[:iri], *operands)] if data[:iri]
      input[:update_op] = SPARQL::Algebra::Expression(:modify, *operands)
    end

    # [42]	DeleteClause	::=	"DELETE" QuadPattern
    start_production(:DeleteClause) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
      self.gen_bnodes
    end
    production(:DeleteClause) do |input, data, callback|
      raise Error, "DeleteClause contains BNode operands: #{Array(data[:pattern]).to_sse}" if Array(data[:pattern]).any?(&:node?)
      self.gen_bnodes(false)
      input[:delete] = SPARQL::Algebra::Expression(:delete, Array(data[:pattern]))
    end

    # [43]	InsertClause	::=	"INSERT" QuadPattern
    start_production(:InsertClause) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables.
      self.gen_bnodes
    end
    production(:InsertClause) do |input, data, callback|
      self.gen_bnodes(false)
      input[:insert] = SPARQL::Algebra::Expression(:insert, Array(data[:pattern]))
    end

    # [44]	UsingClause	::=	"USING" ( iri | "NAMED" iri)
    production(:UsingClause) do |input, data, callback|
      add_prod_data(:using, data[:iri])
    end
    production(:_UsingClause_2) do |input, data, callback|
      input[:iri] = [:named, data[:iri]]
    end

    # [45]	GraphOrDefault	::=	"DEFAULT" | "GRAPH"? iri
    production(:GraphOrDefault) do |input, data, callback|
      if data[:default]
        add_prod_datum(:GraphOrDefault, :default)
      else
        add_prod_data(:GraphOrDefault, data[:iri])
      end
    end

    # [46]	GraphRef	::=	"GRAPH" iri
    production(:GraphRef) do |input, data, callback|
      input[:iri] = data[:iri]
    end

    # [49]	QuadData	::=	"{" Quads "}"
    # QuadData is like QuadPattern, except without BNodes
    start_production(:QuadData) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables
      self.gen_bnodes
    end
    production(:QuadData) do |input, data, callback|
      # Transform using statements instead of patterns, and verify there are no variables
      raise Error, "QuadData contains variable operands: #{Array(data[:pattern]).to_sse}" if Array(data[:pattern]).any?(&:variable?)
      self.gen_bnodes(false)
      input[:pattern] = Array(data[:pattern])
    end

    # [51] QuadsNotTriples	::=	"GRAPH" VarOrIri "{" TriplesTemplate? "}"
    production(:QuadsNotTriples) do |input, data, callback|
      add_prod_datum(:pattern, [SPARQL::Algebra::Expression.for(:graph, data[:VarOrIri].last, Array(data[:pattern]))])
    end

    # [52]	TriplesTemplate	::=	TriplesSameSubject ("." TriplesTemplate? )?
    production(:TriplesTemplate) do |input, data, callback|
      add_prod_datum(:pattern, Array(data[:pattern]))
    end

    # [54]	GroupGraphPatternSub	::=	TriplesBlock? (GraphPatternNotTriples "."? TriplesBlock? )*
    production(:GroupGraphPatternSub) do |input, data, callback|
      debug("GroupGraphPatternSub") {"q #{data[:query].inspect}"}

      res = data[:query].first
      debug("GroupGraphPatternSub(pre-filter)") {"res: #{res.inspect}"}

      if data[:filter]
        expr, query = flatten_filter(data[:filter])
        query = res || SPARQL::Algebra::Operator::BGP.new
        # query should be nil
        res = SPARQL::Algebra::Operator::Filter.new(expr, query)
      end
      add_prod_datum(:query, res)
    end

    # [55]  	TriplesBlock	  ::=  	TriplesSameSubjectPath
    #                               ( '.' TriplesBlock? )?
    production(:TriplesBlock) do |input, data, callback|
      if !Array(data[:pattern]).empty?
        query = SPARQL::Algebra::Operator::BGP.new
        Array(data[:pattern]).each {|p| query << p}

        # Append triples from ('.' TriplesBlock? )?
        Array(data[:query]).each do |q|
          if q.respond_to?(:patterns)
            query += q
          else
            query = SPARQL::Algebra::Operator::Join.new(query, q)
          end
        end
        if (lhs = (input.delete(:query) || []).first) && !lhs.empty?
          query = SPARQL::Algebra::Operator::Join.new(lhs, query)
        end
        add_prod_datum(:query, query)
      elsif !Array(data[:query]).empty?
        # Join query and path
        add_prod_datum(:query, SPARQL::Algebra::Operator::Join.new(data[:path].first, data[:query].first))
      else
        add_prod_datum(:query, data[:path])
      end
    end

    # [56]  	GraphPatternNotTriples	  ::=  	GroupOrUnionGraphPattern
    #                                       | OptionalGraphPattern
    #                                       | MinusGraphPattern
    #                                       | GraphGraphPattern
    #                                       | ServiceGraphPattern
    #                                       | Filter | Bind
    start_production(:GraphPatternNotTriples) do |input, data, callback|
      # Modifies previous graph
      data[:input_query] = input.delete(:query) || [SPARQL::Algebra::Operator::BGP.new]
    end
    production(:GraphPatternNotTriples) do |input, data, callback|
      lhs = data[:input_query].first

      # Filter trickls up to GroupGraphPatternSub
      add_prod_datum(:filter, data[:filter])

      if data[:extend] && lhs.is_a?(SPARQL::Algebra::Operator::Extend)
        # Coalesce extensions
        lhs = lhs.dup
        lhs.operands.first.concat(data[:extend])
        add_prod_datum(:query, lhs)
      elsif data[:extend]
        add_prod_datum(:query, SPARQL::Algebra::Expression.for(:extend, data[:extend], lhs))
      elsif data[:leftjoin]
        add_prod_datum(:query, SPARQL::Algebra::Expression.for(:leftjoin, lhs, *data[:leftjoin]))
      elsif data[:query] && !lhs.empty?
        add_prod_datum(:query, SPARQL::Algebra::Expression.for(:join, lhs, *data[:query]))
      elsif data[:minus]
        add_prod_datum(:query, SPARQL::Algebra::Expression.for(:minus, lhs, *data[:minus]))
      elsif data[:query]
        add_prod_datum(:query, data[:query])
      else
        add_prod_datum(:query, lhs)
      end
    end

    # [57]  	OptionalGraphPattern	  ::=  	'OPTIONAL' GroupGraphPattern
    production(:OptionalGraphPattern) do |input, data, callback|
      expr = nil
      query = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new
      if query.is_a?(SPARQL::Algebra::Operator::Filter)
        # Change to expression on left-join with query element
        expr, query = query.operands
        add_prod_data(:leftjoin, query, expr)
      elsif !query.empty?
        add_prod_data(:leftjoin, query)
      end
    end

    # [58]  	GraphGraphPattern	  ::=  	'GRAPH' VarOrIri GroupGraphPattern
    production(:GraphGraphPattern) do |input, data, callback|
      name = (data[:VarOrIri]).last
      bgp = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new
      if name
        add_prod_data(:query, SPARQL::Algebra::Expression.for(:graph, name, bgp))
      else
        add_prod_data(:query, bgp)
      end
    end

    # [60]  Bind                    ::= 'BIND' '(' Expression 'AS' Var ')'
    production(:Bind) do |input, data, callback|
      add_prod_datum :extend, [data[:Expression].unshift(data[:Var].first)]
    end

    # [61]  InlineData	            ::= 'VALUES' DataBlock
    production(:InlineData) do |input, data, callback|
      debug("InlineData") {"vars: #{data[:Var].inspect}, row: #{data[:row].inspect}"}
      add_prod_datum :query, SPARQL::Algebra::Expression.for(:table,
        data[:Var].unshift(:vars),
        *data[:row]
      )
    end

    # [63]  InlineDataOneVar	      ::= Var '{' DataBlockValue* '}'
    production(:InlineDataOneVar) do |input, data, callback|
      add_prod_datum :Var, data[:Var]

      data[:DataBlockValue].each do |d|
        add_prod_datum :row, [[:row, data[:Var].dup << d]]
      end
    end

    # [64]  InlineDataFull	        ::= ( NIL | '(' Var* ')' )
    #                                '{' ( '(' DataBlockValue* ')' | NIL )* '}'
    production(:InlineDataFull) do |input, data, callback|
      vars = data[:Var]
      add_prod_datum :Var, vars

      if data[:nilrow]
        add_prod_data :row, [:row]
      else
        Array(data[:rowdata]).each do |ds|
          r = [:row]
          ds.each_with_index do |d, i|
            r << [vars[i], d] if d
          end
          add_prod_data :row, r unless r.empty?
        end
      end
    end

    # _InlineDataFull_6	        ::=  '(' '(' DataBlockValue* ')' | NIL ')'
    production(:_InlineDataFull_6) do |input, data, callback|
      if data[:DataBlockValue]
        add_prod_data :rowdata, data[:DataBlockValue].map {|v| v unless v == :undef}
      else
        input[:nilrow] = true
      end
    end

    # [65]  DataBlockValue	        ::= iri | RDFLiteral | NumericLiteral | BooleanLiteral | 'UNDEF'
    production(:DataBlockValue) do |input, data, callback|
      add_prod_datum :DataBlockValue, data.values.first
    end

    # [66]  MinusGraphPattern       ::= 'MINUS' GroupGraphPattern
    production(:MinusGraphPattern) do |input, data, callback|
      query = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new
      add_prod_data(:minus, query)
    end

    # [67]  	GroupOrUnionGraphPattern	  ::=  	GroupGraphPattern
    #                                           ( 'UNION' GroupGraphPattern )*
    production(:GroupOrUnionGraphPattern) do |input, data, callback|
      res = Array(data[:query]).first
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
      input[:union] = Array(data[:union]).unshift(data[:query].first)
    end

    # [68]  	Filter	  ::=  	'FILTER' Constraint
    production(:Filter) do |input, data, callback|
      add_prod_datum(:filter, data[:Constraint])
    end

    # [69]  	Constraint	  ::=  	BrackettedExpression | BuiltInCall
    #                           | FunctionCall
    production(:Constraint) do |input, data, callback|
      if data[:Expression]
        # Resolve expression to the point it is either an atom or an s-exp
        add_prod_data(:Constraint, Array(data[:Expression]).first)
      elsif data[:BuiltInCall]
        add_prod_datum(:Constraint, data[:BuiltInCall])
      elsif data[:Function]
        add_prod_datum(:Constraint, data[:Function])
      end
    end

    # [70]  	FunctionCall	  ::=  	iri ArgList
    production(:FunctionCall) do |input, data, callback|
      add_prod_data(:Function, Array(data[:iri]) + data[:ArgList])
    end

    # [71]  	ArgList	  ::=  	NIL
    #                     | '(' 'DISTINCT'? Expression ( ',' Expression )* ')'
    production(:ArgList) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:ArgList, v)}
    end

    # [72]  	ExpressionList	  ::=  	NIL
    #                             | '(' Expression ( ',' Expression )* ')'
    production(:ExpressionList) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:ExpressionList, v)}
    end

    # [73]  	ConstructTemplate	  ::=  	'{' ConstructTriples? '}'
    start_production(:ConstructTemplate) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables
      self.gen_bnodes
    end
    production(:ConstructTemplate) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables
      self.gen_bnodes(false)
      add_prod_datum(:ConstructTemplate, Array(data[:pattern]))
      add_prod_datum(:ConstructTemplate, data[:ConstructTemplate])
    end

    # [75]  	TriplesSameSubject	  ::=  	VarOrTerm PropertyListNotEmpty
    #                                 |	TriplesNode PropertyList
    production(:TriplesSameSubject) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [77]  	PropertyListNotEmpty	  ::=  	Verb ObjectList
    #                                       ( ';' ( Verb ObjectList )? )*
    start_production(:PropertyListNotEmpty) do |input, data, callback|
      subject = input[:VarOrTerm] || input[:TriplesNode] || input[:GraphNode]
      error(nil, "Expected VarOrTerm or TriplesNode or GraphNode", production: :PropertyListNotEmpty) if validate? && !subject
      data[:Subject] = subject
    end
    production(:PropertyListNotEmpty) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [78]  	Verb	  ::=  	VarOrIri | 'a'
    production(:Verb) do |input, data, callback|
      input[:Verb] = data.values.first
    end

    # [79]  	ObjectList	  ::=  	Object ( ',' Object )*
    start_production(:ObjectList) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:Subject] = prod_data[:Subject]
      error(nil, "Expected Subject", production: :ObjectList) if !prod_data[:Subject] && validate?
      error(nil, "Expected Verb", production: :ObjectList) if !(prod_data[:Verb] || prod_data[:VerbPath]) && validate?
      if prod_data[:Verb]
        data[:Verb] = prod_data[:Verb]
      else
        data[:VerbPath] = prod_data[:VerbPath]
      end
    end
    production(:ObjectList) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:path, data[:path])
    end

    # [80]  	Object	  ::=  	GraphNode
    production(:Object) do |input, data, callback|
      object = data[:VarOrTerm] || data[:TriplesNode] || data[:GraphNode]
      if object
        if prod_data[:Verb]
          add_pattern(:Object, subject: prod_data[:Subject], predicate: prod_data[:Verb], object: object)
          add_prod_datum(:pattern, data[:pattern])
        else
          add_prod_datum(:path,
            SPARQL::Algebra::Expression(:path,
                                        prod_data[:Subject].first,
                                        prod_data[:VerbPath],
                                        object.first))
        end
      end
    end

    # [81]	TriplesSameSubjectPath	::=	VarOrTerm PropertyListPathNotEmpty | TriplesNode PropertyListPath
    production(:TriplesSameSubjectPath) do |input, data, callback|
      if data[:pattern]
        add_prod_datum(:pattern, data[:pattern])
      else
        add_prod_datum(:path, data[:path])
      end
    end

    # [83]  	PropertyListPathNotEmpty	  ::=  	( VerbPath | VerbSimple ) ObjectList ( ';' ( ( VerbPath | VerbSimple ) ObjectList )? )*
    start_production(:PropertyListPathNotEmpty) do |input, data, callback|
      subject = input[:VarOrTerm] || input[:TriplesNode] || input[:GraphNode]
      error(nil, "Expected VarOrTerm, got nothing", production: :PropertyListPathNotEmpty) if validate? && !subject
      data[:Subject] = subject
    end
    production(:PropertyListPathNotEmpty) do |input, data, callback|
      if data[:pattern]
        add_prod_datum(:pattern, data[:pattern])
      else
        add_prod_datum(:path, data[:path])
      end
    end

    # [84]  	VerbPath	  ::=  	Path
    production(:VerbPath) do |input, data, callback|
      if data[:Path]
        input[:VerbPath] = data[:Path]
      else
        input[:Verb] = data[:iri]
      end
    end

    # [85]  	VerbSimple	  ::=  	Var
    production(:VerbSimple) do |input, data, callback|
      input[:Verb] = data.values.flatten.first
    end

    # [86]	ObjectListPath	::=	ObjectPath ("," ObjectPath)*
    start_production(:ObjectListPath) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:Subject] = prod_data[:Subject]
      error(nil, "Expected Subject", production: :ObjectListPath) if !prod_data[:Subject] && validate?
      error(nil, "Expected Verb", production: :ObjectListPath) if !(prod_data[:Verb] || prod_data[:VerbPath]) && validate?
      if prod_data[:Verb]
        data[:Verb] = Array(prod_data[:Verb]).last
      else
        data[:VerbPath] = prod_data[:VerbPath]
      end
    end
    production(:ObjectListPath) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:path, data[:path])
    end

    # [87]  	ObjectPath	  ::=  	GraphNodePath
    production(:ObjectPath) do |input, data, callback|
      object = data[:VarOrTerm] || data[:TriplesNode] || data[:GraphNode]
      if object
        if prod_data[:Verb]
          if data[:pattern] && data[:path]
            # Generate a sequence (for collection of paths)
            data[:pattern].unshift(RDF::Query::Pattern.new(prod_data[:Subject].first, prod_data[:Verb], object.first))
            bgp = SPARQL::Algebra::Expression[:bgp, data[:pattern]]
            add_prod_datum(:path, SPARQL::Algebra::Expression[:sequence, bgp, *data[:path]])
          else
            add_pattern(:Object, subject: prod_data[:Subject], predicate: prod_data[:Verb], object: object)
            add_prod_datum(:pattern, data[:pattern])
          end
        else
          add_prod_datum(:path,
            SPARQL::Algebra::Expression(:path,
                                        Array(prod_data[:Subject]).first,
                                        prod_data[:VerbPath],
                                        object.first))
        end
      end
    end
    # [88]  	Path	  ::=  	PathAlternative
    # output is a :Path or :iri
    production(:Path) do |input, data, callback|
      if data[:Path].is_a?(RDF::URI)
        input[:iri] = data[:Path]
      else
        input[:Path] = data[:Path]
      end
    end

    # [89]  	PathAlternative	  ::=  	PathSequence ( '|' PathSequence )*
    production(:PathAlternative) do |input, data, callback|
      lhs = Array(data[:PathSequence]).shift
      while data[:PathSequence] && !data[:PathSequence].empty?
        rhs = data[:PathSequence].shift
        lhs = SPARQL::Algebra::Expression[:alt, lhs, rhs]
      end
      input[:Path] = lhs
    end

    # ( '|' PathSequence )*
    production(:_PathAlternative_1) do |input, data, callback|
      input[:PathSequence] += data[:PathSequence]
    end

    # [90]  	PathSequence	  ::=  	PathEltOrInverse ( '/' PathEltOrInverse )*
    production(:PathSequence) do |input, data, callback|
      lhs = data[:PathEltOrInverse].shift
      while data[:PathEltOrInverse] && !data[:PathEltOrInverse].empty?
        rhs = data[:PathEltOrInverse].shift
        lhs = SPARQL::Algebra::Expression[:seq, lhs, rhs]
      end
      input[:PathSequence] = [lhs]
    end

    # ( '/' PathEltOrInverse )*
    production(:_PathSequence_1) do |input, data, callback|
      input[:PathEltOrInverse] += data[:PathEltOrInverse]
    end

    # [91]  	PathElt	  ::=  	PathPrimary PathMod?
    production(:PathElt) do |input, data, callback|
      path_mod = data.delete(:PathMod) if data.has_key?(:PathMod)
      path_mod ||= data.delete(:MultiplicativeExpression) if data.has_key?(:MultiplicativeExpression)
      path_mod = path_mod.first if path_mod

      res = data[:PathPrimary]
      res = SPARQL::Algebra::Expression("path#{path_mod}", res) if path_mod
      input[:Path] = res
    end

    # [92]  	PathEltOrInverse	  ::=  	PathElt | '^' PathElt
    production(:PathEltOrInverse) do |input, data, callback|
      res = if data[:reverse]
        SPARQL::Algebra::Expression(:reverse, data[:Path])
      else
        data[:Path]
      end
      input[:PathEltOrInverse] = [res]
    end

    # [94]  	PathPrimary	  ::=  	iri | 'a' | '!' PathNegatedPropertySet | '(' Path ')'
    production(:PathPrimary) do |input, data, callback|
      input[:PathPrimary] = case
      when data[:Verb]                   then data[:Verb]
      when data[:iri]                    then data[:iri]
      when data[:PathNegatedPropertySet] then data[:PathNegatedPropertySet]
      when data[:Path]                   then data[:Path]
      end
    end

    # [95]  	PathNegatedPropertySet	  ::=  	PathOneInPropertySet | '(' ( PathOneInPropertySet ( '|' PathOneInPropertySet )* )? ')'
    production(:PathNegatedPropertySet) do |input, data, callback|
      input[:Path] = SPARQL::Algebra::Expression(:notoneof, *Array(data[:Path]))
    end

    # ( '|' PathOneInPropertySet )* )?
    production(:_PathNegatedPropertySet_4) do |input, data, callback|
      add_prod_datum(:Path, data[:Path])
    end

    # [96]  	PathOneInPropertySet	  ::=  	iri | 'a' | '^' ( iri | 'a' )
    production(:PathOneInPropertySet) do |input, data, callback|
      term = (Array(data[:iri]) || data[:Verb]).first
      term = SPARQL::Algebra::Expression(:reverse, term) if data[:reverse]
      input[:Path] = [term]
    end

    # [98]  	TriplesNode	  ::=  	Collection |	BlankNodePropertyList
    start_production(:TriplesNode) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:TriplesNode] = bnode
    end
    production(:TriplesNode) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:TriplesNode, data[:TriplesNode])
    end

    # [100]	TriplesNodePath	::=	CollectionPath | BlankNodePropertyListPath
    start_production(:TriplesNodePath) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:TriplesNode] = bnode
    end
    production(:TriplesNodePath) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:path, data[:path])
      add_prod_datum(:TriplesNode, data[:TriplesNode])
    end

    # [102]  	Collection	  ::=  	'(' GraphNode+ ')'
    start_production(:Collection) do |input, data, callback|
      # Tells the TriplesNode production to collect and not generate statements
      data[:Collection] = prod_data[:TriplesNode]
    end
    production(:Collection) do |input, data, callback|
      expand_collection(data)
    end

    # [103]	CollectionPath	::=	"(" GraphNodePath+ ")"
    start_production(:CollectionPath) do |input, data, callback|
      # Tells the TriplesNode production to collect and not generate statements
      data[:Collection] = prod_data[:TriplesNode]
    end
    production(:CollectionPath) do |input, data, callback|
      expand_collection(data)
      add_prod_datum(:path, data[:path])
    end

    # [104]  	GraphNode	  ::=  	VarOrTerm |	TriplesNode
    production(:GraphNode) do |input, data, callback|
      term = data[:VarOrTerm] || data[:TriplesNode]
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:GraphNode, term)
    end

    # [105]	GraphNodePath	::=	VarOrTerm | TriplesNodePath
    production(:GraphNodePath) do |input, data, callback|
      term = data[:VarOrTerm] || data[:TriplesNode]
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:path, data[:path])
      add_prod_datum(:GraphNode, term)
    end

    # [106]  	VarOrTerm	  ::=  	Var | GraphTerm
    production(:VarOrTerm) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:VarOrTerm, v)}
    end

    # [107]  	VarOrIri	  ::=  	Var | iri
    production(:VarOrIri) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:VarOrIri, v)}
    end

    # [109]  	GraphTerm	  ::=  	iri |	RDFLiteral |	NumericLiteral
    #                         |	BooleanLiteral |	BlankNode |	NIL
    production(:GraphTerm) do |input, data, callback|
      add_prod_datum(:GraphTerm,
                      data[:iri] ||
                      data[:literal] ||
                      data[:BlankNode] ||
                      data[:NIL])
    end

    # [110]  	Expression	  ::=  	ConditionalOrExpression
    production(:Expression) do |input, data, callback|
      add_prod_datum(:Expression, data[:Expression])
    end

    # [111]  	ConditionalOrExpression	  ::=  	ConditionalAndExpression
    #                                         ( '||' ConditionalAndExpression )*
    production(:ConditionalOrExpression) do |input, data, callback|
      add_operator_expressions(:_OR, data)
    end

    # ( '||' ConditionalAndExpression )*
    production(:_ConditionalOrExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:ConditionalOrExpression, :_OR, data)
    end

    # [112]  	ConditionalAndExpression	  ::=  	ValueLogical ( '&&' ValueLogical )*
    production(:ConditionalAndExpression) do |input, data, callback|
      add_operator_expressions(:_AND, data)
    end

    # ( '||' ConditionalAndExpression )*
    production(:_ConditionalAndExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:ConditionalAndExpression, :_AND, data)
    end

    # [114]  	RelationalExpression	  ::=  	NumericExpression
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
      elsif data[:in]
        expr = (data[:Expression] + data[:in]).reject {|v| v.equal?(RDF.nil)}
        add_prod_datum(:Expression, SPARQL::Algebra::Expression.for(expr.unshift(:in)))
      elsif data[:notin]
        expr = (data[:Expression] + data[:notin]).reject {|v| v.equal?(RDF.nil)}
        add_prod_datum(:Expression, SPARQL::Algebra::Expression.for(expr.unshift(:notin)))
      else
        # NumericExpression with no comparitor
        add_prod_datum(:Expression, data[:Expression])
      end
    end

    # ( '=' NumericExpression | '!=' NumericExpression | ... )?
    production(:_RelationalExpression_1) do |input, data, callback|
      if data[:RelationalExpression]
        add_prod_datum(:_Compare_Numeric, data[:RelationalExpression] + data[:Expression])
      elsif data[:in]
        add_prod_datum(:in, data[:in])
      elsif data[:notin]
        add_prod_datum(:notin, data[:notin])
      end
    end

    # 'IN' ExpressionList
    production(:_RelationalExpression_9) do |input, data, callback|
      add_prod_datum(:in, data[:ExpressionList])
    end

    # 'NOT' 'IN' ExpressionList
    production(:_RelationalExpression_10) do |input, data, callback|
      add_prod_datum(:notin, data[:ExpressionList])
    end

    # [116] AdditiveExpression ::= MultiplicativeExpression
    #                              ( '+' MultiplicativeExpression
    #                              | '-' MultiplicativeExpression
    #                              | ( NumericLiteralPositive | NumericLiteralNegative )
    #                                ( ( '*' UnaryExpression )
    #                              | ( '/' UnaryExpression ) )?
    #                              )*
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
      lit = data[:literal]
      val = lit.to_s
      op, val = val[0,1], val[1..-1]
      add_prod_datum(:AdditiveExpression, op)
      add_prod_datum(:Expression, [lit.class.new(val)])
    end

    # [117]  	MultiplicativeExpression	  ::=  	UnaryExpression
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

    # [118]  	UnaryExpression	  ::=  	  '!' PrimaryExpression
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
          add_prod_datum(:Expression, SPARQL::Algebra::Expression[:"-", e])
        end
      else
        add_prod_datum(:Expression, data[:Expression])
      end
    end

    # [119]  	PrimaryExpression	  ::=  	BrackettedExpression | BuiltInCall
    #                                 | iriOrFunction | RDFLiteral
    #                                 | NumericLiteral | BooleanLiteral
    #                                 | Var
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

    # [121] BuiltInCall             ::= Aggregate
    #                                 | 'STR' '(' Expression ')'
    #                                 | 'LANG' '(' Expression ')'
    #                                 | 'LANGMATCHES' '(' Expression ',' Expression ')'
    #                                 | 'DATATYPE' '(' Expression ')'
    #                                 | 'BOUND' '(' Var ')'
    #                                 | 'IRI' '(' Expression ')'
    #                                 | 'URI' '(' Expression ')'
    #                                 | 'BNODE' ( '(' Expression ')' | NIL )
    #                                 | 'RAND' NIL
    #                                 | 'ABS' '(' Expression ')'
    #                                 | 'CEIL' '(' Expression ')'
    #                                 | 'FLOOR' '(' Expression ')'
    #                                 | 'ROUND' '(' Expression ')'
    #                                 | 'CONCAT' ExpressionList
    #                                 | SubstringExpression
    #                                 | 'STRLEN' '(' Expression ')'
    #                                 | StrReplaceExpression
    #                                 | 'UCASE' '(' Expression ')'
    #                                 | 'LCASE' '(' Expression ')'
    #                                 | 'ENCODE_FOR_URI' '(' Expression ')'
    #                                 | 'CONTAINS' '(' Expression ',' Expression ')'
    #                                 | 'STRSTARTS' '(' Expression ',' Expression ')'
    #                                 | 'STRENDS' '(' Expression ',' Expression ')'
    #                                 | 'STRBEFORE' '(' Expression ',' Expression ')'
    #                                 | 'STRAFTER' '(' Expression ',' Expression ')'
    #                                 | 'YEAR' '(' Expression ')'
    #                                 | 'MONTH' '(' Expression ')'
    #                                 | 'DAY' '(' Expression ')'
    #                                 | 'HOURS' '(' Expression ')'
    #                                 | 'MINUTES' '(' Expression ')'
    #                                 | 'SECONDS' '(' Expression ')'
    #                                 | 'TIMEZONE' '(' Expression ')'
    #                                 | 'TZ' '(' Expression ')'
    #                                 | 'NOW' NIL
    #                                 | 'UUID' NIL
    #                                 | 'STRUUID' NIL
    #                                 | 'MD5' '(' Expression ')'
    #                                 | 'SHA1' '(' Expression ')'
    #                                 | 'SHA224' '(' Expression ')'
    #                                 | 'SHA256' '(' Expression ')'
    #                                 | 'SHA384' '(' Expression ')'
    #                                 | 'SHA512' '(' Expression ')'
    #                                 | 'COALESCE' ExpressionList
    #                                 | 'IF' '(' Expression ',' Expression ',' Expression ')'
    #                                 | 'STRLANG' '(' Expression ',' Expression ')'
    #                                 | 'STRDT' '(' Expression ',' Expression ')'
    #                                 | 'sameTerm' '(' Expression ',' Expression ')'
    #                                 | 'isIRI' '(' Expression ')'
    #                                 | 'isURI' '(' Expression ')'
    #                                 | 'isBLANK' '(' Expression ')'
    #                                 | 'isLITERAL' '(' Expression ')'
    #                                 | 'isNUMERIC' '(' Expression ')'
    #                                 | RegexExpression
    #                                 | ExistsFunc
    #                                 | NotExistsFunc
    production(:BuiltInCall) do |input, data, callback|
      input[:BuiltInCall] = if builtin = data.keys.detect {|k| BUILTINS.include?(k)}
        SPARQL::Algebra::Expression.for(
          (data[:ExpressionList] || data[:Expression] || []).
          unshift(builtin))
      elsif builtin_rule = data.keys.detect {|k| BUILTIN_RULES.include?(k)}
        SPARQL::Algebra::Expression.for(data[builtin_rule].unshift(builtin_rule))
      elsif aggregate_rule = data.keys.detect {|k| AGGREGATE_RULES.include?(k)}
        data[aggregate_rule].first
      elsif data[:bound]
        SPARQL::Algebra::Expression.for(data[:Var].unshift(:bound))
      elsif data[:BuiltInCall]
        SPARQL::Algebra::Expression.for(data[:BuiltInCall] + data[:Expression])
      end
    end

    # [122]  	RegexExpression	  ::=  	'REGEX' '(' Expression ',' Expression
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

    # [125]  	ExistsFunc	  ::=  	'EXISTS' GroupGraphPattern
    production(:ExistsFunc) do |input, data, callback|
      add_prod_datum(:exists, data[:query])
    end

    # [126]  	NotExistsFunc	  ::=  	'NOT' 'EXISTS' GroupGraphPattern
    production(:NotExistsFunc) do |input, data, callback|
      add_prod_datum(:notexists, data[:query])
    end

    # [127] Aggregate               ::= 'COUNT' '(' 'DISTINCT'? ( '*' | Expression ) ')'
    #                                 | 'SUM' '(' 'DISTINCT'? Expression ')'
    #                                 | 'MIN' '(' 'DISTINCT'? Expression ')'
    #                                 | 'MAX' '(' 'DISTINCT'? Expression ')'
    #                                 | 'AVG' '(' 'DISTINCT'? Expression ')'
    #                                 | 'SAMPLE' '(' 'DISTINCT'? Expression ')'
    #                                 | 'GROUP_CONCAT' '(' 'DISTINCT'? Expression
    #                                   ( ';' 'SEPARATOR' '=' String )? ')'
    production(:Aggregate) do |input, data, callback|
      if aggregate_rule = data.keys.detect {|k| AGGREGATE_RULES.include?(k)}
        parts = [aggregate_rule]
        parts << [:separator, RDF::Literal(data[:string])] if data[:separator] && data[:string]
        parts << :distinct if data[:DISTINCT_REDUCED]
        parts << data[:Expression].first if data[:Expression]
        add_prod_data(aggregate_rule, SPARQL::Algebra::Expression.for(parts))
      end
    end

    # [128]  	iriOrFunction	  ::=  	iri ArgList?
    production(:iriOrFunction) do |input, data, callback|
      if data.has_key?(:ArgList)
        # Function is (func arg1 arg2 ...)
        add_prod_data(:Function, Array(data[:iri]) + data[:ArgList])
      else
        input[:iri] = data[:iri]
      end
    end

    # [129]  	RDFLiteral	  ::=  	String ( LANGTAG | ( '^^' iri ) )?
    production(:RDFLiteral) do |input, data, callback|
      if data[:string]
        lit = data.dup
        str = lit.delete(:string)
        lit[:datatype] = lit.delete(:iri) if lit[:iri]
        lit[:language] = lit.delete(:language).last.downcase if lit[:language]
        input[:literal] = RDF::Literal.new(str, lit) if str
      end
    end

    # [132]  	NumericLiteralPositive	  ::=  	INTEGER_POSITIVE
    #                                       |	DECIMAL_POSITIVE
    #                                       |	DOUBLE_POSITIVE
    production(:NumericLiteralPositive) do |input, data, callback|
      num = data.values.flatten.last
      input[:literal] = num

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [133]  	NumericLiteralNegative	  ::=  	INTEGER_NEGATIVE
    #                                       |	DECIMAL_NEGATIVE
    #                                       |	DOUBLE_NEGATIVE
    production(:NumericLiteralNegative) do |input, data, callback|
      num = data.values.flatten.last
      input[:literal] = num

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    ##
    # Initializes a new parser instance.
    #
    # @param  [String, IO, StringIO, #to_s]          input
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
    # @yield  [parser] `self`
    # @yieldparam  [SPARQL::Grammar::Parser] parser
    # @yieldreturn [void] ignored
    # @return [SPARQL::Grammar::Parser]
    def initialize(input = nil, options = {}, &block)
      @input = case input
      when IO, StringIO then input.read
      else input.to_s.dup
      end
      @input.encode!(Encoding::UTF_8) if @input.respond_to?(:encode!)
      @options = {anon_base: "b0", validate: false}.merge(options)
      @options[:debug] ||= case
      when options[:progress] then 2
      when options[:validate] then 1
      end

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
      true
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
    # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    # @see http://axel.deri.ie/sparqltutorial/ESWC2007_SPARQL_Tutorial_unit2b.pdf
    def parse(prod = START)
      ll1_parse(@input, prod.to_sym, @options.merge(branch: BRANCH,
                                                    first: FIRST,
                                                    follow: FOLLOW,
                                                    whitespace: WS)
      ) do |context, *data|
        case context
        when :trace
          level, lineno, depth, *args = data
          message = args.to_sse
          d_str = depth > 100 ? ' ' * 100 + '+' : ' ' * depth
          str = "[#{lineno}](#{level})#{d_str}#{message}".chop
          case @options[:debug]
          when Array
            @options[:debug] << str unless level > 2
          when TrueClass
            $stderr.puts str
          when Integer
            $stderr.puts(str) if level <= @options[:debug]
          end
        end
      end

      # The last thing on the @prod_data stack is the result
      @result = case
      when !prod_data.is_a?(Hash)
        prod_data
      when prod_data.empty?
        nil
      when prod_data[:query]
        Array(prod_data[:query]).length == 1 ? prod_data[:query].first : prod_data[:query]
      when prod_data[:update]
        prod_data[:update]
      else
        key = prod_data.keys.first
        [key] + Array(prod_data[key])  # Creates [:key, [:triple], ...]
      end

      # Validate resulting expression
      @result.validate! if @result && validate?
      @result
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
    #     dc: RDF::URI('http://purl.org/dc/terms/'),
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

    # Generate BNodes, not non-distinguished variables
    # @param [Boolean] value
    # @return [void]
    def gen_bnodes(value = true)
      @nd_var_gen = value ? false : "0"
    end

    # Clear cached BNodes
    # @return [void]
    def clear_bnode_cache
      @bnode_cache = {}
    end

    # Freeze BNodes, which allows us to detect if they're re-used
    # @return [void]
    def freeze_bnodes
      @bnode_cache ||= {}
      @bnode_cache.each_value(&:freeze)
    end

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
        @bnode_cache ||= {}
        raise Error, "Illegal attempt to reuse a BNode" if @bnode_cache[id] && @bnode_cache[id].frozen?
        @bnode_cache[id] ||= RDF::Node.new(id)
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
      value = RDF::URI(value)
      if base_uri && value.relative?
        u = base_uri.join(value)
        u.lexical = "<#{value}>" unless resolve_iris?
        u
      else
        value
      end
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
      RDF::Literal.new(value, options.merge(validate: validate?))
    end

    # Take collection of objects and create RDF Collection using rdf:first, rdf:rest and rdf:nil
    # @param [Hash] data Production Data
    def expand_collection(data)
      # Add any triples generated from deeper productions
      add_prod_datum(:pattern, data[:pattern])

      # Create list items for each element in data[:GraphNode]
      first = data[:Collection]
      list = Array(data[:GraphNode]).flatten.compact
      last = list.pop

      list.each do |r|
        add_pattern(:Collection, subject: first, predicate: RDF["first"], object: r)
        rest = bnode()
        add_pattern(:Collection, subject: first, predicate: RDF["rest"], object: rest)
        first = rest
      end

      if last
        add_pattern(:Collection, subject: first, predicate: RDF["first"], object: last)
      end
      add_pattern(:Collection, subject: first, predicate: RDF["rest"], object: RDF["nil"])
    end

    # add a pattern
    #
    # @param [String] production Production generating pattern
    # @param [Hash{Symbol => Object}] options
    def add_pattern(production, options)
      progress(production, "[:pattern, #{options[:subject]}, #{options[:predicate]}, #{options[:object]}]")
      triple = {}
      options.each_pair do |r, v|
        if v.is_a?(Array) && v.flatten.length == 1
          v = v.flatten.first
        end
        if validate? && !v.is_a?(RDF::Term)
          error("add_pattern", "Expected #{r} to be a resource, but it was #{v.inspect}",
            production: production)
        end
        triple[r] = v
      end
      add_prod_datum(:pattern, RDF::Query::Pattern.new(triple))
    end

    # Flatten a Data in form of filter: [op+ bgp?], without a query into filter and query creating exprlist, if necessary
    # @return [Array[:expr, query]]
    def flatten_filter(data)
      query = data.pop if data.last.is_a?(SPARQL::Algebra::Query)
      expr = data.length > 1 ? SPARQL::Algebra::Operator::Exprlist.new(*data) : data.first
      [expr, query]
    end

    # Merge query modifiers, datasets, and projections
    #
    # This includes tranforming aggregates if also used with a GROUP BY
    #
    # @see http://www.w3.org/TR/sparql11-query/#convertGroupAggSelectExpressions
    def merge_modifiers(data)
      debug("merge modifiers") {data.inspect}
      query = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new

      vars = data[:Var] || []
      order = data[:order] ? data[:order].first : []
      extensions = data.fetch(:extend, [])
      having = data.fetch(:having, [])
      values = data.fetch(:ValuesClause, []).first

      # extension variables must not appear in projected variables.
      # Add them to the projection otherwise
      extensions.each do |(var, expr)|
        raise Error, "Extension variable #{var} also in SELECT" if vars.map(&:to_s).include?(var.to_s)
        vars << var
      end

      # If any extension contains an aggregate, and there is now group, implicitly group by 1
      if !data[:group] &&
         extensions.any? {|(var, function)| function.aggregate?} ||
         having.any? {|c| c.aggregate? }
        debug {"Implicit group"}
        data[:group] = [[]]
      end

      # Add datasets and modifiers in order
      if data[:group]
        group_vars = data[:group].first

        # For creating temporary variables
        agg = 0

        # Find aggregated varirables in extensions
        aggregates = []
        aggregated_vars = extensions.map do |(var, function)|
          var if function.aggregate?
        end.compact

        # Common function for replacing aggregates with temporary variables,
        # as defined in http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#convertGroupAggSelectExpressions
        aggregate_expression = lambda do |expr|
          # Replace unaggregated variables in expr
          # - For each unaggregated variable V in X
          expr.replace_vars! do |v|
            aggregated_vars.include?(v) ? v : SPARQL::Algebra::Expression[:sample, v]
          end

          # Replace aggregates in expr as above
          expr.replace_aggregate! do |function|
            if avf = aggregates.detect {|(v, f)| f == function}
              avf.first
            else
              # Allocate a temporary variable for this function, and retain the mapping for outside the group
              av = RDF::Query::Variable.new(".#{agg}")
              av.distinguished = false
              agg += 1
              aggregates << [av, function]
              av
            end
          end
        end

        # If there are extensions, they are aggregated if necessary and bound
        # to temporary variables
        extensions.map! do |(var, expr)|
          [var, aggregate_expression.call(expr)]
        end

        # Having clauses
        having.map! do |expr|
          aggregate_expression.call(expr)
        end

        query = if aggregates.empty?
          SPARQL::Algebra::Expression[:group, group_vars, query]
        else
          SPARQL::Algebra::Expression[:group, group_vars, aggregates, query]
        end
      end

      if values
        query = query ? SPARQL::Algebra::Expression[:join, query, values] : values
      end

      query = SPARQL::Algebra::Expression[:extend, extensions, query] unless extensions.empty?

      query = SPARQL::Algebra::Expression[:filter, *having, query] unless having.empty?

      query = SPARQL::Algebra::Expression[:order, data[:order].first, query] unless order.empty?

      query = SPARQL::Algebra::Expression[:project, vars, query] unless vars.empty?

      query = SPARQL::Algebra::Expression[data[:DISTINCT_REDUCED], query] if data[:DISTINCT_REDUCED]

      query = SPARQL::Algebra::Expression[:slice, data[:slice][0], data[:slice][1], query] if data[:slice]

      query = SPARQL::Algebra::Expression[:dataset, data[:dataset], query] if data[:dataset]

      query
    end

    # Add joined expressions in for prod1 (op prod2)* to form (op (op 1 2) 3)
    def add_operator_expressions(production, data)
      # Iterate through expression to create binary operations
      lhs = data[:Expression]
      while data[production] && !data[production].empty?
        op, rhs = data[production].shift, data[production].shift
        lhs = SPARQL::Algebra::Expression[op + lhs + rhs]
      end
      add_prod_datum(:Expression, lhs)
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
  end # class Parser
end # module SPARQL::Grammar
