require 'ebnf'
require 'ebnf/ll1/parser'
require 'sparql/grammar/meta11'

module SPARQL::Grammar
  ##
  # A parser for the SPARQL 1.1 grammar.
  #
  # @see https://www.w3.org/TR/sparql11-query/#grammar
  # @see https://en.wikipedia.org/wiki/LR_parser
  class Parser11
    include SPARQL::Grammar::Meta11
    include SPARQL::Grammar::Terminals
    include EBNF::LL1::Parser

    # Builtin functions
    BUILTINS = %w{
      ABS ADJUST BNODE CEIL COALESCE CONCAT
      CONTAINS DATATYPE DAY ENCODE_FOR_URI
      FLOOR HOURS IF IRI LANGMATCHES LANG LCASE
      MD5 MINUTES MONTH NOW RAND ROUND SECONDS
      SHA1 SHA224 SHA256 SHA384 SHA512
      STRAFTER STRBEFORE STRDT STRENDS STRLANG STRLEN STRSTARTS STRUUID STR
      TIMEZONE TZ UCASE URI UUID YEAR
      isBLANK isIRI isURI isLITERAL isNUMERIC sameTerm
      isTRIPLE TRIPLE SUBJECT PREDICATE OBJECT
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
      input[:language] = token.value[1..-1]
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
          ABS|ADJUST|ALL|AVG|BNODE|BOUND|CEIL|COALESCE|CONCAT
         |CONTAINS|COUNT|DATATYPE|DAY|DEFAULT|ENCODE_FOR_URI|EXISTS
         |FLOOR|HOURS|IF|GRAPH|GROUP_CONCAT|IRI|LANGMATCHES|LANG|LCASE
         |MAX|MD5|MINUTES|MIN|MONTH|NAMED|NOW|RAND|REPLACE|ROUND|SAMPLE|SECONDS|SEPARATOR
         |SHA1|SHA224|SHA256|SHA384|SHA512|SILENT
         |STRAFTER|STRBEFORE|STRDT|STRENDS|STRLANG|STRLEN|STRSTARTS|STRUUID|SUBSTR|STR|SUM
         |TIMEZONE|TZ|UCASE|UNDEF|URI|UUID|YEAR
         |isBLANK|isIRI|isURI|isLITERAL|isNUMERIC|sameTerm
         |isTRIPLE|TRIPLE|SUBJECT|PREDICATE|OBJECT
        }x
        add_prod_datum(token.value.downcase.to_sym, token.value.downcase.to_sym)
      else
        #add_prod_datum(:string, token.value)
      end
    end

    # Productions

    # [2] Query ::= Prologue ( SelectQuery | ConstructQuery | DescribeQuery | AskQuery )
    #
    # Inputs from `data` are `:query` and potentially `:PrefixDecl`.
    # Output to prod_data is the Queryable object.
    production(:Query) do |input, data, callback|
      query = data[:query].first if data[:query]

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

    # [4] Prologue ::= ( BaseDecl | PrefixDecl )*
    #
    # Inputs from `data` are `:PrefixDecl` and `:BaseDecl`.
    # Output to prod_data is the same, if `#resolve_iris?` is `false`.
    production(:Prologue) do |input, data, callback|
      unless resolve_iris?
        # Only output if we're not resolving URIs internally
        add_prod_datum(:BaseDecl, data[:BaseDecl])
        add_prod_datum(:PrefixDecl, data[:PrefixDecl])
      end
    end

    # [5] BaseDecl ::= 'BASE' IRI_REF
    #
    # Input from `data` is `:BaseDecl`.
    # Output to prod_data is the same, if `#resolve_iris?` is `false`.
    production(:BaseDecl) do |input, data, callback|
      iri = data[:iri]
      debug("BaseDecl") {"Defined base as #{iri}"}
      self.base_uri = iri(iri)
      add_prod_datum(:BaseDecl, iri) unless resolve_iris?
    end

    # [6] PrefixDecl ::= 'PREFIX' PNAME_NS IRI_REF
    #
    # Inputs from `data` are `:iri`, and `:prefix`.
    # Output to prod_data is the `:PrefixDecl`, and `Operator::Prefix`, unless there is no `:iri`.
    production(:PrefixDecl) do |input, data, callback|
      if data[:iri]
        pfx = data[:prefix]
        self.prefix(pfx, data[:iri])
        prefix_op = SPARQL::Algebra::Operator::Prefix.new([["#{pfx}:".to_sym, data[:iri]]], [])
        add_prod_datum(:PrefixDecl, prefix_op)
      end
    end

    # [7] SelectQuery ::= SelectClause DatasetClause* WhereClause SolutionModifier
    #
    # Inputs from `data` are merged into a Queryable object.
    # Output to prod_data is `:query`.
    production(:SelectQuery) do |input, data, callback|
      query = merge_modifiers(data)
      add_prod_datum :query, query
    end

    # [8] SubSelect ::= SelectClause WhereClause SolutionModifier
    #
    # Inputs from `data` are merged into a Queryable object.
    # Output to prod_data is `:query`.
    production(:SubSelect) do |input, data, callback|
      query = merge_modifiers(data)
      add_prod_datum :query, query
    end

    # [9] SelectClause ::= 'SELECT' ( 'DISTINCT' | 'REDUCED' )? ( ( Var | ( '(' Expression 'AS' Var ')' ) )+ | '*' )
    # [9.2] _SelectClause_2 ::= ( ( Var | ( '(' Expression 'AS' Var ')' ) )+ | '*' )
    #
    # Inputs from `data` are `:Expression` and `:Var`.
    # Output to prod_data is `:Var`.
    production(:_SelectClause_2) do |input, data, callback|
      if data[:MultiplicativeExpression]
        add_prod_datum :Var, %i(*)
      else
        add_prod_datum :extend, data[:extend]
        add_prod_datum :Var, data[:Var]
      end
    end
    # [9.8] _SelectClause_8 ::= ( '(' Expression 'AS' Var ')' )
    #
    # Inputs from `data` are `:Expression` and `:Var`.
    # Output to prod_data is `:extend`.
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
    #
    # Inputs from `data` are `:pattern` and optionally `:ConstructTemplate`.
    # If there is no `:query` in data, one is constructed by creating a BGP from all values of `:pattern`.
    # Output to prod_data is `:query` made by creating a Operator::Construct using any `:ConstructTemplate` or `:pattern` and the query with merged modifiers.
    production(:ConstructQuery) do |input, data, callback|
      data[:query] ||= [SPARQL::Algebra::Operator::BGP.new(*data[:pattern])]
      query = merge_modifiers(data)
      template = data[:ConstructTemplate] || data[:pattern] || []
      add_prod_datum :query, SPARQL::Algebra::Expression[:construct, template, query]
    end

    # [11] DescribeQuery ::= 'DESCRIBE' ( VarOrIri+ | '*' )
    #                         DatasetClause* WhereClause? SolutionModifier
    #
    # Inputs from `data` are merged into a Queryable object.
    # Outputs are created using any `:VarOrIri` in data is used as an argument, along with the Queryable object to create an `Operator::Describe` object, which is added to `:query` in prod datea.
    production(:DescribeQuery) do |input, data, callback|
      query = merge_modifiers(data)
      to_describe = Array(data[:VarOrIri])
      add_prod_datum :query, SPARQL::Algebra::Expression[:describe, to_describe, query]
    end

    # [12] AskQuery ::= 'ASK' DatasetClause* WhereClause
    #
    # Inputs from `data` are merged into a Queryable object.
    # Output to prod_data is `:query` made by creating a Operator::Ask using the query with merged modifiers.
    production(:AskQuery) do |input, data, callback|
      query = merge_modifiers(data)
      add_prod_datum :query, SPARQL::Algebra::Expression[:ask, query]
    end

    # [14] DefaultGraphClause ::= SourceSelector
    #
    # Input from `data` is `:iri`.
    # Output to prod_data is `:dataset` taken from `:iri`.
    production(:DefaultGraphClause) do |input, data, callback|
      add_prod_datum :dataset, data[:iri]
    end

    # [15] NamedGraphClause ::= 'NAMED' SourceSelector
    #
    # Input from `data` is `:iri`.
    # Output to prod_data is `:dataset` taken from `:iri`.
    production(:NamedGraphClause) do |input, data, callback|
      add_prod_data :dataset, [:named, data[:iri]]
    end

    # [18] SolutionModifier ::= GroupClause? HavingClause? OrderClause? LimitOffsetClauses?

    # [19] GroupClause ::= 'GROUP' 'BY' GroupCondition+
    #
    # Input from `data` is `:GroupCondition`.
    # Output to prod_data is `:group` taken from `:GroupCondition`.
    production(:GroupClause) do |input, data, callback|
      add_prod_data :group, data[:GroupCondition]
    end

    # [20] GroupCondition ::= BuiltInCall | FunctionCall
    #                       | '(' Expression ( 'AS' Var )? ')' | Var
    #
    # Output to prod_data is `:GroupCondition` taken from first value in data.
    production(:GroupCondition) do |input, data, callback|
      add_prod_datum :GroupCondition, data.values.first
    end

    # _GroupCondition_1 ::= '(' Expression ( 'AS' Var )? ')'
    #
    # Input from `data` is `:Expression` and optionally `:Var`.
    # Output to prod_data is `:GroupCondition` taken from `:Expression` prepended by any value of `:Var`.
    production(:_GroupCondition_1) do |input, data, callback|
      cond = if data[:Var]
        [data[:Expression].unshift(data[:Var].first)]
      else
        data[:Expression]
      end
      add_prod_datum(:GroupCondition, cond)
    end

    # [21] HavingClause ::= 'HAVING' HavingCondition+
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:HavingClause) do |input, data, callback|
      add_prod_datum(:having, data[:Constraint])
    end

    # [23] OrderClause ::= 'ORDER' 'BY' OrderCondition+
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:OrderClause) do |input, data, callback|
      if res = data[:OrderCondition]
        res = [res] if [:asc, :desc].include?(res[0]) # Special case when there's only one condition and it's ASC (x) or DESC (x)
        add_prod_data :order, res
      end
    end

    # [24] OrderCondition ::= ( ( 'ASC' | 'DESC' )
    #                           BrackettedExpression )
    #                       | ( Constraint | Var )
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:OrderCondition) do |input, data, callback|
      if data[:OrderDirection]
        add_prod_datum(:OrderCondition, SPARQL::Algebra::Expression(data[:OrderDirection], *data[:Expression]))
      else
        add_prod_datum(:OrderCondition, data[:Constraint] || data[:Var])
      end
    end

    # [25] LimitOffsetClauses ::= LimitClause OffsetClause?
    #                           | OffsetClause LimitClause?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:LimitOffsetClauses) do |input, data, callback|
      if data[:limit] || data[:offset]
        limit = data[:limit] ? data[:limit].last : :_
        offset = data[:offset] ? data[:offset].last : :_
        add_prod_data :slice, offset, limit
      end
    end

    # [26] LimitClause ::= 'LIMIT' INTEGER
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:LimitClause) do |input, data, callback|
      add_prod_datum(:limit, data[:literal])
    end

    # [27] OffsetClause ::= 'OFFSET' INTEGER
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:OffsetClause) do |input, data, callback|
      add_prod_datum(:offset, data[:literal])
    end

    # [28]  ValuesClause ::= ( 'VALUES' DataBlock )?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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

    # [29] Update ::= Prologue (Update1 (";" Update)? )?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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

    # [30] Update1 ::= Load | Clear | Drop | Add | Move | Copy
    #                | Create | InsertData | DeleteData | DeleteWhere | Modify
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Update1) do |input, data, callback|
      input[:update] = SPARQL::Algebra::Expression.for(:update, data[:update_op])
    end

    # [31] Load ::= "LOAD" "SILENT"? iri ("INTO" GraphRef)?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Load) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args << data[:iri]
      args << data[:into] if data[:into]
      input[:update_op] = SPARQL::Algebra::Expression(:load, *args)
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_Load_2) do |input, data, callback|
      input[:into] = data[:iri]
    end

    # [32] Clear ::= "CLEAR" "SILENT"? GraphRefAll
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Clear) do |input, data, callback|
      args = []
      %w(silent default named all).map(&:to_sym).each do |s|
        args << s if data[s]
      end
      args += Array(data[:iri])
      input[:update_op] = SPARQL::Algebra::Expression(:clear, *args)
    end

    # [33] Drop ::= "DROP" "SILENT"? GraphRefAll
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Drop) do |input, data, callback|
      args = []
      %w(silent default named all).map(&:to_sym).each do |s|
        args << s if data[s]
      end
      args += Array(data[:iri])
      input[:update_op] = SPARQL::Algebra::Expression(:drop, *args)
    end

    # [34] Create ::= "CREATE" "SILENT"? GraphRef
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Create) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args += Array(data[:iri])
      input[:update_op] = SPARQL::Algebra::Expression(:create, *args)
    end

    # [35] Add ::= "ADD" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    #
    # Input from `data` are `GraphOrDefault` and optionally `:silent`.
    # Output to input is `:update_op` with an `Operator::Add` object.
    production(:Add) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args += data[:GraphOrDefault]
      input[:update_op] = SPARQL::Algebra::Expression(:add, *args)
    end

    # [36] Move ::= "MOVE" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Move) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args += data[:GraphOrDefault]
      input[:update_op] = SPARQL::Algebra::Expression(:move, *args)
    end

    # [37] Copy ::= "COPY" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Copy) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args += data[:GraphOrDefault]
      input[:update_op] = SPARQL::Algebra::Expression(:copy, *args)
    end

    # [38] InsertData ::= "INSERT DATA" QuadData
    start_production(:InsertData) do |input, data, callback|
      # Freeze existing bnodes, so that if an attempt is made to re-use such a node, and error is raised
      self.freeze_bnodes
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:InsertData) do |input, data, callback|
      input[:update_op] = SPARQL::Algebra::Expression(:insertData, data[:pattern])
    end

    # [39] DeleteData ::= "DELETE DATA" QuadData
    start_production(:DeleteData) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
      self.gen_bnodes
    end
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:DeleteData) do |input, data, callback|
      raise Error, "DeleteData contains BNode operands: #{data[:pattern].to_sse}" if Array(data[:pattern]).any?(&:node?)
      input[:update_op] = SPARQL::Algebra::Expression(:deleteData, Array(data[:pattern]))
    end

    # [40] DeleteWhere ::= "DELETE WHERE" QuadPattern
    start_production(:DeleteWhere) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
      self.gen_bnodes
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:DeleteWhere) do |input, data, callback|
      raise Error, "DeleteWhere contains BNode operands: #{data[:pattern].to_sse}" if Array(data[:pattern]).any?(&:node?)
      self.gen_bnodes(false)
      input[:update_op] = SPARQL::Algebra::Expression(:deleteWhere, Array(data[:pattern]))
    end

    # [41] Modify ::= ("WITH" iri)? ( DeleteClause InsertClause? | InsertClause) UsingClause* "WHERE" GroupGraphPattern
    start_production(:Modify) do |input, data, callback|
      self.clear_bnode_cache
    end

    #
    # Input from `data` are:
    #   * `:query` from `GroupGraphPattern`,
    #   * optionally `:using` from `UsingClause`,
    #   * either `:delete` or `:insert` or both from `DeleteClause` and `InsertClause`, and
    #   * optionally `:iri` from `WITH`
    # Output to input is `:update_op`.
    production(:Modify) do |input, data, callback|
      query = data[:query].first if data[:query]
      query = SPARQL::Algebra::Expression.for(:using, data[:using], query) if data[:using]
      operands = [query, data[:delete], data[:insert]].compact
      operands = [SPARQL::Algebra::Expression.for(:with, data[:iri], *operands)] if data[:iri]
      input[:update_op] = SPARQL::Algebra::Expression(:modify, *operands)
    end

    # [42] DeleteClause ::= "DELETE" QuadPattern
    #
    # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
    start_production(:DeleteClause) do |input, data, callback|
      self.gen_bnodes
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:DeleteClause) do |input, data, callback|
      raise Error, "DeleteClause contains BNode operands: #{Array(data[:pattern]).to_sse}" if Array(data[:pattern]).any?(&:node?)
      self.gen_bnodes(false)
      input[:delete] = SPARQL::Algebra::Expression(:delete, Array(data[:pattern]))
    end

    # [43] InsertClause ::= "INSERT" QuadPattern
    #
    # Generate BNodes instead of non-distinguished variables.
    start_production(:InsertClause) do |input, data, callback|
      self.gen_bnodes
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:InsertClause) do |input, data, callback|
      self.gen_bnodes(false)
      input[:insert] = SPARQL::Algebra::Expression(:insert, Array(data[:pattern]))
    end

    # [44] UsingClause ::= "USING" ( iri | "NAMED" iri)
    production(:UsingClause) do |input, data, callback|
      add_prod_data(:using, data[:iri])
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_UsingClause_2) do |input, data, callback|
      input[:iri] = [:named, data[:iri]]
    end

    # [45] GraphOrDefault ::= "DEFAULT" | "GRAPH"? iri
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:GraphOrDefault) do |input, data, callback|
      if data[:default]
        add_prod_datum(:GraphOrDefault, :default)
      else
        add_prod_data(:GraphOrDefault, data[:iri])
      end
    end

    # [46] GraphRef ::= "GRAPH" iri
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:GraphRef) do |input, data, callback|
      input[:iri] = data[:iri]
    end

    # [49] QuadData ::= "{" Quads "}"
    # QuadData is like QuadPattern, except without BNodes
    start_production(:QuadData) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables
      self.gen_bnodes
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:QuadData) do |input, data, callback|
      # Transform using statements instead of patterns, and verify there are no variables
      raise Error, "QuadData contains variable operands: #{Array(data[:pattern]).to_sse}" if Array(data[:pattern]).any?(&:variable?)
      self.gen_bnodes(false)
      input[:pattern] = Array(data[:pattern])
    end

    # [51] QuadsNotTriples ::= "GRAPH" VarOrIri "{" TriplesTemplate? "}"
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:QuadsNotTriples) do |input, data, callback|
      add_prod_datum(:pattern, [SPARQL::Algebra::Expression.for(:graph, data[:VarOrIri].last, Array(data[:pattern]))])
    end

    # [52] TriplesTemplate ::= TriplesSameSubject ("." TriplesTemplate? )?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:TriplesTemplate) do |input, data, callback|
      add_prod_datum(:pattern, Array(data[:pattern]))
    end

    # [54] GroupGraphPatternSub ::= TriplesBlock? (GraphPatternNotTriples "."? TriplesBlock? )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:GroupGraphPatternSub) do |input, data, callback|
      debug("GroupGraphPatternSub") {"q #{data[:query].inspect}"}

      res = case Array(data[:query]).length
      when 0 then SPARQL::Algebra::Operator::BGP.new
      when 1 then data[:query].first
      when 2
        SPARQL::Algebra::Operator::Join.new(*data[:query])
      else
        error(nil, "Expected 0-2 queryies, got #{data[:query].length}", production: :GroupGraphPatternSub)
        SPARQL::Algebra::Operator::BGP.new
      end
      debug("GroupGraphPatternSub(pre-filter)") {"res: #{res.inspect}"}

      if data[:filter]
        expr, query = flatten_filter(data[:filter])
        query = res
        # query should be nil
        res = SPARQL::Algebra::Operator::Filter.new(expr, query)
      end
      add_prod_datum(:query, res)
    end

    # [55] TriplesBlock ::= TriplesSameSubjectPath
    #                       ( '.' TriplesBlock? )?
    #
    # Input from `data` is `:pattern` and `:query`. Input from input is also `:pattern`
    # Patterns are sequenced and segmented into RDF::Query::Pattern and Operator::Path.
    # Output to prod_data is `:query` either a BGP, a Join, a Sequence, or a combination of any of these. Any path element results in a Sequence.
    production(:TriplesBlock) do |input, data, callback|
      raise "TriplesBlock without pattern" if Array(data[:pattern]).empty?

      lhs = Array(input.delete(:query)).first

      # Sequence is existing patterns, plus new patterns, plus patterns from TriplesBlock?
      sequence = []
      unless lhs.nil? || lhs.empty?
        if lhs.is_a?(SPARQL::Algebra::Operator::Sequence)
          sequence += lhs.operands
        else
          sequence << lhs
        end
      end

      sequence += data[:pattern]

      # Append triples from ('.' TriplesBlock? )?
      Array(data[:query]).each do |q|
        if q.is_a?(SPARQL::Algebra::Operator::Sequence)
          q.operands.each do |op|
            sequence += op.respond_to?(:patterns) ? op.patterns : [op]
          end
        elsif q.respond_to?(:patterns)
          sequence += q.patterns
        else
          sequence << q
        end
      end

      # Merge runs of patterns into BGPs
      patterns = []
      new_seq = []
      sequence.each do |element|
        case element
        when RDF::Query::Pattern
          patterns << element
        when RDF::Queryable
          patterns += element.patterns
        else
          new_seq << SPARQL::Algebra::Expression.for(:bgp, *patterns) unless patterns.empty?
          patterns = []
          new_seq << element
        end
      end
      new_seq << SPARQL::Algebra::Expression.for(:bgp, *patterns) unless patterns.empty?

      # Optionally create a sequence, if there are enough gathered.
      # FIXME: Join?
      query = if new_seq.length > 1
        if new_seq.any? {|e| e.is_a?(SPARQL::Algebra::Operator::Path)}
          SPARQL::Algebra::Expression.for(:sequence, *new_seq)
        else
          SPARQL::Algebra::Expression.for(:join, *new_seq)
        end
      else
        new_seq.first
      end

      add_prod_datum(:query, query)
    end

    # [56] GraphPatternNotTriples ::= GroupOrUnionGraphPattern
    #                               | OptionalGraphPattern
    #                               | MinusGraphPattern
    #                               | GraphGraphPattern
    #                               | ServiceGraphPattern
    #                               | Filter | Bind
    start_production(:GraphPatternNotTriples) do |input, data, callback|
      # Modifies previous graph
      data[:input_query] = input.delete(:query)
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:GraphPatternNotTriples) do |input, data, callback|
      lhs = Array(data[:input_query]).first || SPARQL::Algebra::Operator::BGP.new

      # Filter trickls up to GroupGraphPatternSub
      add_prod_datum(:filter, data[:filter])

      if data[:extend] && lhs.is_a?(SPARQL::Algebra::Operator::Extend)
        # Coalesce extensions
        lhs = lhs.dup
        lhs.operands.first.concat(data[:extend])
        add_prod_datum(:query, lhs)
      elsif data[:extend]
        # The variable assigned in a BIND clause must not be already in-use within the immediately preceding TriplesBlock within a GroupGraphPattern.
        # None of the variables on the lhs of data[:extend] may be used in lhs
        data[:extend].each do |(v, _)|
          error(nil, "BIND Variable #{v} used in pattern", production: :GraphPatternNotTriples) if lhs.vars.map(&:to_sym).include?(v.to_sym)
        end
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

    # [57] OptionalGraphPattern ::= 'OPTIONAL' GroupGraphPattern
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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

    # [58] GraphGraphPattern ::= 'GRAPH' VarOrIri GroupGraphPattern
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:GraphGraphPattern) do |input, data, callback|
      name = (data[:VarOrIri]).last
      bgp = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new
      if name
        add_prod_data(:query, SPARQL::Algebra::Expression.for(:graph, name, bgp))
      else
        add_prod_data(:query, bgp)
      end
    end

    # [59]  ServiceGraphPattern ::= 'SERVICE' 'SILENT'? VarOrIri GroupGraphPattern
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ServiceGraphPattern) do |input, data, callback|
      args = []
      args << :silent if data[:silent]
      args << (data[:VarOrIri]).last
      args << data.fetch(:query, [SPARQL::Algebra::Operator::BGP.new]).first
      service = SPARQL::Algebra::Expression.for(:service, *args)
      add_prod_data(:query, service)
    end

    # [60]  Bind ::= 'BIND' '(' Expression 'AS' Var ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Bind) do |input, data, callback|
      add_prod_datum :extend, [data[:Expression].unshift(data[:Var].first)]
    end

    # [61]  InlineData ::= 'VALUES' DataBlock
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:InlineData) do |input, data, callback|
      debug("InlineData") {"vars: #{data[:Var].inspect}, row: #{data[:row].inspect}"}
      add_prod_datum :query, SPARQL::Algebra::Expression.for(:table,
        Array(data[:Var]).unshift(:vars),
        *data[:row]
      )
    end

    # [63]  InlineDataOneVar ::= Var '{' DataBlockValue* '}'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:InlineDataOneVar) do |input, data, callback|
      add_prod_datum :Var, data[:Var]

      Array(data[:DataBlockValue]).each do |d|
        add_prod_datum :row, [[:row, data[:Var].dup << d]]
      end
    end

    # [64]  InlineDataFull ::= ( NIL | '(' Var* ')' )
    #                          '{' ( '(' DataBlockValue* ')' | NIL )* '}'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:InlineDataFull) do |input, data, callback|
      vars = data[:Var]
      add_prod_datum :Var, vars

      if data[:nilrow]
        add_prod_data :row, [:row]
      else
        Array(data[:rowdata]).each do |ds|
          if ds.length < data[:Var].length
            raise Error, "Too few values in a VALUE clause compared to the number of variables"
          elsif ds.length > data[:Var].length
            raise Error, "Too many values in a VALUE clause compared to the number of variables"
          end
          r = [:row]
          ds.each_with_index do |d, i|
            r << [vars[i], d] if d
          end
          add_prod_data :row, r unless r.empty?
        end
      end
    end

    # _InlineDataFull_6 ::=  '(' '(' DataBlockValue* ')' | NIL ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_InlineDataFull_6) do |input, data, callback|
      if data[:DataBlockValue]
        add_prod_data :rowdata, data[:DataBlockValue].map {|v| v unless v == :undef}
      else
        input[:nilrow] = true
      end
    end

    # [65]  DataBlockValue ::= QuotedTriple | iri | RDFLiteral | NumericLiteral | BooleanLiteral | 'UNDEF'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:DataBlockValue) do |input, data, callback|
      add_prod_datum :DataBlockValue, data.values.first
    end

    # [66]  MinusGraphPattern ::= 'MINUS' GroupGraphPattern
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:MinusGraphPattern) do |input, data, callback|
      query = data[:query] ? data[:query].first : SPARQL::Algebra::Operator::BGP.new
      add_prod_data(:minus, query)
    end

    # [67] GroupOrUnionGraphPattern ::= GroupGraphPattern
    #                                           ( 'UNION' GroupGraphPattern )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_GroupOrUnionGraphPattern_1) do |input, data, callback|
      input[:union] = Array(data[:union]).unshift(data[:query].first)
    end

    # [68] Filter ::= 'FILTER' Constraint
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Filter) do |input, data, callback|
      add_prod_datum(:filter, data[:Constraint])
    end

    # [69] Constraint ::= BrackettedExpression | BuiltInCall
    #                           | FunctionCall
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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

    # [70] FunctionCall ::= iri ArgList
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:FunctionCall) do |input, data, callback|
      add_prod_data(:Function, SPARQL::Algebra::Operator::FunctionCall.new(data[:iri], *data[:ArgList]))
    end

    # [71] ArgList ::= NIL
    #                     | '(' 'DISTINCT'? Expression ( ',' Expression )* ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ArgList) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:ArgList, v)}
    end

    # [72] ExpressionList ::= NIL
    #                             | '(' Expression ( ',' Expression )* ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ExpressionList) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:ExpressionList, v)}
    end

    # [73] ConstructTemplate ::= '{' ConstructTriples? '}'
    start_production(:ConstructTemplate) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables
      self.gen_bnodes
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ConstructTemplate) do |input, data, callback|
      # Generate BNodes instead of non-distinguished variables
      self.gen_bnodes(false)
      add_prod_datum(:ConstructTemplate, Array(data[:pattern]))
      add_prod_datum(:ConstructTemplate, data[:ConstructTemplate])
    end

    # [75] TriplesSameSubject ::= VarOrTermOrQuotedTP PropertyListNotEmpty
    #                                 | TriplesNode PropertyList
    production(:TriplesSameSubject) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [77] PropertyListNotEmpty ::= Verb ObjectList
    #                                       ( ';' ( Verb ObjectList )? )*
    start_production(:PropertyListNotEmpty) do |input, data, callback|
      subject = input[:VarOrTermOrQuotedTP] || input[:TriplesNode] || input[:GraphNode]
      error(nil, "Expected VarOrTermOrQuotedTP or TriplesNode or GraphNode", production: :PropertyListNotEmpty) if validate? && !subject
      data[:Subject] = subject
    end
    production(:PropertyListNotEmpty) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [78] Verb ::= VarOrIri | 'a'
    #
    # Output to input is `:Verb`.
    production(:Verb) do |input, data, callback|
      input[:Verb] = data.values.first
    end

    # [79] ObjectList ::= Object ( ',' Object )*
    #
    # Adds `:Subject`, `:Verb`, and `:VerbPath` from input to data with error checking.
    start_production(:ObjectList) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:Subject] = input[:Subject]
      error(nil, "Expected Subject", production: :ObjectList) if !input[:Subject] && validate?
      error(nil, "Expected Verb", production: :ObjectList) if !(input[:Verb] || input[:VerbPath]) && validate?
      data[:Verb] = input[:Verb] if input[:Verb]
      data[:VerbPath] = input[:VerbPath] if input[:VerbPath]
    end
    production(:ObjectList) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [80] Object ::= GraphNode AnnotationPattern?
    #
    # Sets `:Subject` and `:Verb` in data from input.
    start_production(:Object) do |input, data, callback|
      data[:Subject] = Array(input[:Subject]).first
      data[:Verb] = Array(input[:Verb]).first
    end

    #
    # Input from `data` is `:Subject`, `:Verb` or `:VerbPath`, and `GraphNode`.
    # Output to prod_data is `:pattern`, either from `:Subject`, `:Verb`, and `GraphNode` or a new path if `VerbPath` is present instead of `Verb`.
    production(:Object) do |input, data, callback|
      object = data[:GraphNode]
      add_prod_datum(:pattern, data[:pattern])
      if object
        if input[:Verb]
          add_pattern(:Object, subject: input[:Subject], predicate: input[:Verb], object: object)
        elsif input[:VerbPath]
          add_prod_datum(:pattern,
            SPARQL::Algebra::Expression(:path,
                                        input[:Subject].first,
                                        input[:VerbPath],
                                        object.first))
        end
      end
    end

    # AnnotationPattern?
    start_production(:_Object_1) do |input, data, callback|
      pattern = RDF::Query::Pattern.new(input[:Subject], input[:Verb], input[:GraphNode].first, quoted: true)
      error("ObjectPath", "Expected Verb",
        production: :_Object_1) unless input[:Verb]
      data[:TriplesNode] = [pattern]
    end
    production(:_Object_1) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [81] TriplesSameSubjectPath ::= VarOrTermOrQuotedTP PropertyListPathNotEmpty | TriplesNode PropertyListPath
    production(:TriplesSameSubjectPath) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [83] PropertyListPathNotEmpty ::= ( VerbPath | VerbSimple ) ObjectList
    #                                   ( ';' ( ( VerbPath | VerbSimple )
    #                                           ObjectList )? )*
    #
    # Sets `:Subject` in data from either `:VarOrTermOrQuotedTP`,
    # `:TriplesNode`, or `:GraphNode` in input with error checking.
    start_production(:PropertyListPathNotEmpty) do |input, data, callback|
      subject = input[:VarOrTermOrQuotedTP] || input[:TriplesNode] || input[:GraphNode]
      error(nil, "Expected VarOrTermOrQuotedTP, got nothing", production: :PropertyListPathNotEmpty) if validate? && !subject
      data[:Subject] = subject
    end
    production(:PropertyListPathNotEmpty) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [84] VerbPath ::= Path
    #
    # Input from `data` is `:Path` or `:iri`.
    # Output to prod_data is either `:VerbPath` or `:Verb`.
    # If `:VerbPath` is added, then any existing `:Verb` is removed.
    production(:VerbPath) do |input, data, callback|
      if data[:Path]
        input.delete(:Verb)
        input[:VerbPath] = data[:Path]
      else
        input[:Verb] = data[:iri]
      end
    end

    # [85] VerbSimple ::= Var
    production(:VerbSimple) do |input, data, callback|
      input[:Verb] = data.values.flatten.first
    end

    # [86] ObjectListPath ::= ObjectPath ("," ObjectPath)*
    #
    # Addes `:Subject` from input to data with error checking.
    # Also adds either `:Verb` or `:VerbPath`
    start_production(:ObjectListPath) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:Subject] = input[:Subject]
      error(nil, "Expected Subject", production: :ObjectListPath) if !input[:Subject] && validate?
      error(nil, "Expected Verb", production: :ObjectListPath) if !(input[:Verb] || input[:VerbPath]) && validate?
      if input[:Verb]
        data[:Verb] = Array(input[:Verb]).last
      else
        data[:VerbPath] = input[:VerbPath]
      end
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ObjectListPath) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [87] ObjectPath ::= GraphNodePath AnnotationPatternPath?
    #
    # Adds `:Subject` and `:Verb` to data from input.
    start_production(:ObjectPath) do |input, data, callback|
      data[:Subject] = Array(input[:Subject]).first
      data[:Verb] = Array(input[:Verb]).first
    end

    # Input from `data` `:Subject`, either `:Verb` or `:VerbPath`, `:GraphNode` from GraphNodePath is used as the object, and `:pattern`.
    # Output to prod_data is either a pattern including `:Subject`, `:Verb` and `:GraphNode`, or an `Object::Path` using `:VerbPath` instead of `:Verb`. Also, any `:pattern` from data is sent to prod_ddata
    production(:ObjectPath) do |input, data, callback|
      subject = data[:Subject]
      verb = data[:Verb]
      object = Array(data[:GraphNode]).first
      if verb
        add_prod_datum(:pattern, RDF::Query::Pattern.new(subject, verb, object))
      else
        add_prod_datum(:pattern, SPARQL::Algebra::Expression(:path,
                                        subject,
                                        input[:VerbPath],
                                        object))
      end
      add_prod_datum(:pattern, data[:pattern])
    end

    # AnnotationPatternPath?
    #
    # Create `:TriplesNode` in data used as the subject of annotations
    start_production(:_ObjectPath_1) do |input, data, callback|
      error("ObjectPath", "Expected Verb",
        production: :_ObjectPath_1) unless input[:Verb]
      pattern = RDF::Query::Pattern.new(input[:Subject], input[:Verb], input[:GraphNode].first, quoted: true)
      data[:TriplesNode] = [pattern]
    end

    #
    # Input from `data` is `:pattern`.
    # Output to prod_data is `:pattern`.
    production(:_ObjectPath_1) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [88] Path ::= PathAlternative
    #
    # Input from data is `:Path`
    # Output to input is either `:iri` or `:Path`, depending on if `:Path` is an IRI or not.
    production(:Path) do |input, data, callback|
      if data[:Path].is_a?(RDF::URI)
        input[:iri] = data[:Path]
      else
        input[:Path] = data[:Path]
      end
    end

    # [89] PathAlternative ::= PathSequence ( '|' PathSequence )*
    #
    # Input from `data` is `:PathSequence` containing one or more path objects.
    # Output to prod_data is `:Path`, containing a nested sequence of `Algebra::Alt` connecting the elements from `:PathSequence`, unless there is only one such element, in which case it is added directly.
    production(:PathAlternative) do |input, data, callback|
      lhs = Array(data[:PathSequence]).shift
      while data[:PathSequence] && !data[:PathSequence].empty?
        rhs = data[:PathSequence].shift
        lhs = SPARQL::Algebra::Expression[:alt, lhs, rhs]
      end
      input[:Path] = lhs
    end

    # ( '|' PathSequence )*
    #
    # Input from `data` is `:PathSequence`.
    # Output to prod_data is `:PathSequence` which is accumulated.
    production(:_PathAlternative_1) do |input, data, callback|
      input[:PathSequence] += data[:PathSequence]
    end

    # [90] PathSequence ::= PathEltOrInverse ( '/' PathEltOrInverse )*
    #
    # Input from `data` is `:PathSequence` containing one or more path objects.
    # Output to prod_data is `:Path`, containing a nested sequence of `Algebra::Seq` connecting the elements from `:PathSequence`, unless there is only one such element, in which case it is added directly.
    production(:PathSequence) do |input, data, callback|
      lhs = data[:PathEltOrInverse].shift
      while data[:PathEltOrInverse] && !data[:PathEltOrInverse].empty?
        rhs = data[:PathEltOrInverse].shift
        lhs = SPARQL::Algebra::Expression[:seq, lhs, rhs]
      end
      input[:PathSequence] = [lhs]
    end

    # ( '/' PathEltOrInverse )*
    #
    # Input from `data` is `:PathSequence`.
    # Output to prod_data is `:PathSequence` which is accumulated.
    production(:_PathSequence_1) do |input, data, callback|
      input[:PathEltOrInverse] += data[:PathEltOrInverse]
    end

    # [91] PathElt ::= PathPrimary PathMod?
    #
    # Input from `data` is `:PathMod` and `:PathPrimary`.
    # Output to prod_data is `:Path` a possibly modified `:PathPrimary`.
    production(:PathElt) do |input, data, callback|
      path_mod = data.delete(:PathMod) if data.has_key?(:PathMod)
      path_mod ||= data.delete(:MultiplicativeExpression) if data.has_key?(:MultiplicativeExpression)
      path_mod = path_mod.first if path_mod

      res = case path_mod
      when SPARQL::Algebra::Expression
        # Path range :p{m,n}
        path_mod.operands[2] = data[:PathPrimary]
        path_mod
      when nil
        data[:PathPrimary]
      else
        SPARQL::Algebra::Expression("path#{path_mod}", data[:PathPrimary])
      end
      input[:Path] = res
    end

    # [92] PathEltOrInverse ::= PathElt | '^' PathElt
    #
    # Input from `data` is `:reverse` and `:Path`.
    # Output to prod_data is `:Path` a possibly reversed `:Path`.
    production(:PathEltOrInverse) do |input, data, callback|
      res = if data[:reverse]
        SPARQL::Algebra::Expression(:reverse, data[:Path])
      else
        data[:Path]
      end
      input[:PathEltOrInverse] = [res]
    end

    # [93]  PathMod ::= '*' | '?' | '+' | '{' INTEGER? (',' INTEGER?)? '}'
    # '{' INTEGER? (',' INTEGER?)? '}'
    start_production(:_PathMod_1) do |input, data, callback|
      data[:pathRange] = [nil]
    end
    production(:_PathMod_1) do |input, data, callback|
      raise Error, "expect property range to have integral elements" if data[:pathRange].all?(&:nil?)
      min, max = data[:pathRange]
      min ||= 0
      max = min if data[:pathRange].length == 1
      max ||= :*

      # Last operand added in :PathElt
      add_prod_data(:PathMod, SPARQL::Algebra::Expression(:pathRange, min, max, RDF.nil))
    end

    # INTEGER?
    production(:_PathMod_2) do |input, data, callback|
      input[:pathRange][0] = data[:literal].object
    end

    # (',' INTEGER?)
    start_production(:_PathMod_4) do |input, data, callback|
      data[:pathRange] = [nil, nil]
    end
    production(:_PathMod_4) do |input, data, callback|
      input[:pathRange][1] ||= data.fetch(:pathRange, [0, nil])[1]
    end

    # INTEGER?
    production(:_PathMod_5) do |input, data, callback|
      input[:pathRange][1] = data[:literal].object
    end

    # [94] PathPrimary ::= iri | 'a' | '!' PathNegatedPropertySet | '(' Path ')'
    #
    # Input from `data` is one of `:Verb`, `:iri`, `:PathNegatedPropertySet`, or `:Path`.
    # Output to prod_data is `:PathPrimary`.
    production(:PathPrimary) do |input, data, callback|
      input[:PathPrimary] = case
      when data[:Verb]                   then data[:Verb]
      when data[:iri]                    then data[:iri]
      when data[:PathNegatedPropertySet] then data[:PathNegatedPropertySet]
      when data[:Path]                   then data[:Path]
      end
    end

    # [95] PathNegatedPropertySet ::= PathOneInPropertySet | '(' ( PathOneInPropertySet ( '|' PathOneInPropertySet )* )? ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:PathNegatedPropertySet) do |input, data, callback|
      input[:Path] = SPARQL::Algebra::Expression(:notoneof, *Array(data[:Path]))
    end

    # ( '|' PathOneInPropertySet )* )?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_PathNegatedPropertySet_4) do |input, data, callback|
      add_prod_datum(:Path, data[:Path])
    end

    # [96] PathOneInPropertySet ::= iri | 'a' | '^' ( iri | 'a' )
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:PathOneInPropertySet) do |input, data, callback|
      term = (Array(data[:iri]) || data[:Verb]).first
      term = SPARQL::Algebra::Expression(:reverse, term) if data[:reverse]
      input[:Path] = [term]
    end

    # [98] TriplesNode ::= Collection | BlankNodePropertyList
    start_production(:TriplesNode) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:TriplesNode] = bnode
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:TriplesNode) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:TriplesNode, data[:TriplesNode])
    end

    # [100] TriplesNodePath ::= CollectionPath | BlankNodePropertyListPath
    start_production(:TriplesNodePath) do |input, data, callback|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:TriplesNode] = bnode
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:TriplesNodePath) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:TriplesNode, data[:TriplesNode])
    end

    # [102] Collection ::= '(' GraphNode+ ')'
    start_production(:Collection) do |input, data, callback|
      # Tells the TriplesNode production to collect and not generate statements
      data[:Collection] = input[:TriplesNode]
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Collection) do |input, data, callback|
      expand_collection(data)
    end

    # [103] CollectionPath ::= "(" GraphNodePath+ ")"
    start_production(:CollectionPath) do |input, data, callback|
      # Tells the TriplesNode production to collect and not generate statements
      data[:Collection] = input[:TriplesNode]
    end

    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:CollectionPath) do |input, data, callback|
      expand_collection(data)
    end

    # [104] GraphNode ::= VarOrTermOrQuotedTP | TriplesNode
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:GraphNode) do |input, data, callback|
      term = data[:VarOrTermOrQuotedTP] || data[:TriplesNode]
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:GraphNode, term)
    end

    # [105] GraphNodePath ::= VarOrTermOrQuotedTP | TriplesNodePath
    #
    # Input from `data` is either `:VarOrTermOrQUotedTP` or `:TriplesNode`.
    # Additionally, `:pattern`. Also, `:pattern` and `:path`.
    # Output to prod_data is `:GraphNode`, along with any `:path` and `:pattern`.
    production(:GraphNodePath) do |input, data, callback|
      term = data[:VarOrTermOrQuotedTP] || data[:TriplesNode]
      add_prod_datum(:pattern, data[:pattern])
      add_prod_datum(:GraphNode, term)
    end

    # [106s] VarOrTermOrQuotedTP ::= Var | GraphTerm | QuotedTP
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:VarOrTermOrQuotedTP) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:VarOrTermOrQuotedTP, v)}
    end

    # [107] VarOrIri ::= Var | iri
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:VarOrIri) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:VarOrIri, v)}
    end

    # [109] GraphTerm ::= iri | RDFLiteral | NumericLiteral
    #                         | BooleanLiteral | BlankNode | NIL
    #
    # Input from `data` is one of `:iri`, `:literal`, `:BlankNode`, or `:NIL`.
    # Output to prod_data is `:GraphTerm` created from the data.
    production(:GraphTerm) do |input, data, callback|
      add_prod_datum(:GraphTerm,
                      data[:iri] ||
                      data[:literal] ||
                      data[:BlankNode] ||
                      data[:NIL])
    end

    # [110] Expression ::= ConditionalOrExpression
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Expression) do |input, data, callback|
      add_prod_datum(:Expression, data[:Expression])
    end

    # [111] ConditionalOrExpression ::= ConditionalAndExpression
    #                                   ( '||' ConditionalAndExpression )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ConditionalOrExpression) do |input, data, callback|
      add_operator_expressions(:_OR, data)
    end

    # ( '||' ConditionalAndExpression )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_ConditionalOrExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:ConditionalOrExpression, :_OR, data)
    end

    # [112] ConditionalAndExpression ::= ValueLogical ( '&&' ValueLogical )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ConditionalAndExpression) do |input, data, callback|
      add_operator_expressions(:_AND, data)
    end

    # ( '||' ConditionalAndExpression )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_ConditionalAndExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:ConditionalAndExpression, :_AND, data)
    end

    # [114] RelationalExpression ::= NumericExpression
    #                                ( '=' NumericExpression
    #                                | '!=' NumericExpression
    #                                | '<' NumericExpression
    #                                | '>' NumericExpression
    #                                | '<=' NumericExpression
    #                                | '>=' NumericExpression
    #                                | 'IN' ExpressionList
    #                                | 'NOT' 'IN' ExpressionList
    #                                )?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:RelationalExpression) do |input, data, callback|
      if data[:_Compare_Numeric]
        add_prod_datum(:Expression, SPARQL::Algebra::Expression.for(data[:_Compare_Numeric].insert(1, *data[:Expression])))
      elsif data[:in]
        expr = (data[:Expression] + data[:in]).reject {|v| v.eql?(RDF.nil)}
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
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_RelationalExpression_9) do |input, data, callback|
      add_prod_datum(:in, data[:ExpressionList])
    end

    # 'NOT' 'IN' ExpressionList
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_RelationalExpression_10) do |input, data, callback|
      add_prod_datum(:notin, data[:ExpressionList])
    end

    # [116] AdditiveExpression ::= MultiplicativeExpression
    #                              ( '+' MultiplicativeExpression
    #                              | '-' MultiplicativeExpression
    #                              | ( NumericLiteralPositive
    #                                | NumericLiteralNegative )
    #                                ( ( '*' UnaryExpression )
    #                              | ( '/' UnaryExpression ) )?
    #                              )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:AdditiveExpression) do |input, data, callback|
      add_operator_expressions(:_Add_Sub, data)
    end

    # ( '+' MultiplicativeExpression
    # | '-' MultiplicativeExpression
    # | ( NumericLiteralPositive | NumericLiteralNegative )
    #   ( ( '*' UnaryExpression )
    # | ( '/' UnaryExpression ) )?
    # )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_AdditiveExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:AdditiveExpression, :_Add_Sub, data)
    end

    # | ( NumericLiteralPositive | NumericLiteralNegative )
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_AdditiveExpression_7) do |input, data, callback|
      lit = data[:literal]
      val = lit.to_s
      op, val = val[0,1], val[1..-1]
      add_prod_datum(:AdditiveExpression, op)
      add_prod_datum(:Expression, [lit.class.new(val)])
    end

    # [117] MultiplicativeExpression ::= UnaryExpression
    #                                    ( '*' UnaryExpression
    #                                    | '/' UnaryExpression )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:MultiplicativeExpression) do |input, data, callback|
      add_operator_expressions(:_Mul_Div, data)
    end

    # ( '*' UnaryExpression
    # | '/' UnaryExpression )*
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:_MultiplicativeExpression_1) do |input, data, callback|
      accumulate_operator_expressions(:MultiplicativeExpression, :_Mul_Div, data)
    end

    # [118] UnaryExpression ::= '!' PrimaryExpression
    #                         | '+' PrimaryExpression
    #                         | '-' PrimaryExpression
    #                         | PrimaryExpression
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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

    # [119] PrimaryExpression ::= BrackettedExpression | BuiltInCall
    #                           | iriOrFunction | RDFLiteral
    #                           | NumericLiteral | BooleanLiteral
    #                           | Var
    #                           | ExprQuotedTP
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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
      elsif data[:pattern]
        add_prod_datum(:Expression, data[:pattern])
      end

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [121] BuiltInCall ::= Aggregate
    #                     | 'STR' '(' Expression ')'
    #                     | 'LANG' '(' Expression ')'
    #                     | 'LANGMATCHES' '(' Expression ',' Expression ')'
    #                     | 'DATATYPE' '(' Expression ')'
    #                     | 'BOUND' '(' Var ')'
    #                     | 'IRI' '(' Expression ')'
    #                     | 'URI' '(' Expression ')'
    #                     | 'BNODE' ( '(' Expression ')' | NIL )
    #                     | 'RAND' NIL
    #                     | 'ABS' '(' Expression ')'
    #                     | 'CEIL' '(' Expression ')'
    #                     | 'FLOOR' '(' Expression ')'
    #                     | 'ROUND' '(' Expression ')'
    #                     | 'CONCAT' ExpressionList
    #                     | SubstringExpression
    #                     | 'STRLEN' '(' Expression ')'
    #                     | StrReplaceExpression
    #                     | 'UCASE' '(' Expression ')'
    #                     | 'LCASE' '(' Expression ')'
    #                     | 'ENCODE_FOR_URI' '(' Expression ')'
    #                     | 'CONTAINS' '(' Expression ',' Expression ')'
    #                     | 'STRSTARTS' '(' Expression ',' Expression ')'
    #                     | 'STRENDS' '(' Expression ',' Expression ')'
    #                     | 'STRBEFORE' '(' Expression ',' Expression ')'
    #                     | 'STRAFTER' '(' Expression ',' Expression ')'
    #                     | 'YEAR' '(' Expression ')'
    #                     | 'MONTH' '(' Expression ')'
    #                     | 'DAY' '(' Expression ')'
    #                     | 'HOURS' '(' Expression ')'
    #                     | 'MINUTES' '(' Expression ')'
    #                     | 'SECONDS' '(' Expression ')'
    #                     | 'TIMEZONE' '(' Expression ')'
    #                     | 'TZ' '(' Expression ')'
    #                     | 'NOW' NIL
    #                     | 'UUID' NIL
    #                     | 'STRUUID' NIL
    #                     | 'MD5' '(' Expression ')'
    #                     | 'SHA1' '(' Expression ')'
    #                     | 'SHA224' '(' Expression ')'
    #                     | 'SHA256' '(' Expression ')'
    #                     | 'SHA384' '(' Expression ')'
    #                     | 'SHA512' '(' Expression ')'
    #                     | 'COALESCE' ExpressionList
    #                     | 'IF' '(' Expression ',' Expression ',' Expression ')'
    #                     | 'STRLANG' '(' Expression ',' Expression ')'
    #                     | 'STRDT' '(' Expression ',' Expression ')'
    #                     | 'sameTerm' '(' Expression ',' Expression ')'
    #                     | 'isIRI' '(' Expression ')'
    #                     | 'isURI' '(' Expression ')'
    #                     | 'isBLANK' '(' Expression ')'
    #                     | 'isLITERAL' '(' Expression ')'
    #                     | 'isNUMERIC' '(' Expression ')'
    #                     | RegexExpression
    #                     | ExistsFunc
    #                     | NotExistsFunc
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
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

    # [122] RegexExpression ::= 'REGEX' '(' Expression ',' Expression
    #                           ( ',' Expression )? ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:RegexExpression) do |input, data, callback|
      add_prod_datum(:regex, data[:Expression])
    end

    # [123] SubstringExpression ::= 'SUBSTR'
    #                               '(' Expression ',' Expression
    #                               ( ',' Expression )? ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:SubstringExpression) do |input, data, callback|
      add_prod_datum(:substr, data[:Expression])
    end

    # [124] StrReplaceExpression ::= 'REPLACE'
    #                                '(' Expression ','
    #                                Expression ',' Expression
    #                                ( ',' Expression )? ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:StrReplaceExpression) do |input, data, callback|
      add_prod_datum(:replace, data[:Expression])
    end

    # [125] ExistsFunc ::= 'EXISTS' GroupGraphPattern
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ExistsFunc) do |input, data, callback|
      add_prod_datum(:exists, data[:query])
    end

    # [126] NotExistsFunc ::= 'NOT' 'EXISTS' GroupGraphPattern
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:NotExistsFunc) do |input, data, callback|
      add_prod_datum(:notexists, data[:query])
    end

    # [127] Aggregate ::= 'COUNT' '(' 'DISTINCT'? ( '*' | Expression ) ')'
    #                   | 'SUM' '(' 'DISTINCT'? Expression ')'
    #                   | 'MIN' '(' 'DISTINCT'? Expression ')'
    #                   | 'MAX' '(' 'DISTINCT'? Expression ')'
    #                   | 'AVG' '(' 'DISTINCT'? Expression ')'
    #                   | 'SAMPLE' '(' 'DISTINCT'? Expression ')'
    #                   | 'GROUP_CONCAT' '(' 'DISTINCT'? Expression
    #                     ( ';' 'SEPARATOR' '=' String )? ')'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:Aggregate) do |input, data, callback|
      if aggregate_rule = data.keys.detect {|k| AGGREGATE_RULES.include?(k)}
        parts = [aggregate_rule]
        parts << [:separator, RDF::Literal(data[:string])] if data[:separator] && data[:string]
        parts << :distinct if data[:DISTINCT_REDUCED]
        parts << data[:Expression].first if data[:Expression]
        add_prod_data(aggregate_rule, SPARQL::Algebra::Expression.for(parts))
      end
    end

    # [128] iriOrFunction ::= iri ArgList?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:iriOrFunction) do |input, data, callback|
      if data.has_key?(:ArgList)
        # Function is (func arg1 arg2 ...)
        add_prod_data(:Function, SPARQL::Algebra::Operator::FunctionCall.new(data[:iri], *data[:ArgList]))
      else
        input[:iri] = data[:iri]
      end
    end

    # [129] RDFLiteral ::= String ( LANGTAG | ( '^^' iri ) )?
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:RDFLiteral) do |input, data, callback|
      if data[:string]
        lit = data.dup
        str = lit.delete(:string)
        lit[:datatype] = lit.delete(:iri) if lit[:iri]
        lit[:language] = lit.delete(:language).downcase if lit[:language]
        input[:literal] = RDF::Literal.new(str, **lit) if str
      end
    end

    # [132] NumericLiteralPositive ::= INTEGER_POSITIVE
    #                                | DECIMAL_POSITIVE
    #                                | DOUBLE_POSITIVE
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:NumericLiteralPositive) do |input, data, callback|
      num = data.values.flatten.last
      input[:literal] = num

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [133] NumericLiteralNegative ::= INTEGER_NEGATIVE
    #                                | DECIMAL_NEGATIVE
    #                                | DOUBLE_NEGATIVE
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:NumericLiteralNegative) do |input, data, callback|
      num = data.values.flatten.last
      input[:literal] = num

      # Keep track of this for parent UnaryExpression production
      add_prod_datum(:UnaryExpression, data[:UnaryExpression])
    end

    # [174] QuotedTP ::= '<<' qtSubjectOrObject Verb qtSubjectOrObject '>>'
    #
    # Input from `data` is `:qtSubjectOrObject` from which subject and object are extracted and `:Verb` from which predicate is extracted.
    # Output to prod_data is `:QuotedTP` containing subject, predicate, and object.
    production(:QuotedTP) do |input, data, callback|
      subject, object = data[:qtSubjectOrObject]
      predicate = data[:Verb]
      add_pattern(:QuotedTP,
                  subject: subject,
                  predicate: predicate,
                  object: object,
                  quoted: true)
    end

    # [175] QuotedTriple ::= '<<' DataValueTerm (iri | 'a') DataValueTerm '>>'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:QuotedTriple) do |input, data, callback|
      subject, object = data[:DataValueTerm]
      predicate = data[:iri]
      add_pattern(:QuotedTriple,
                  subject: subject,
                  predicate: predicate,
                  object: object,
                  quoted: true)
    end

    # [176] qtSubjectOrObject ::= Var | BlankNode | iri | RDFLiteral
    #                           | NumericLiteral | BooleanLiteral | QuotedTP
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:qtSubjectOrObject) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:qtSubjectOrObject, v)}
    end

    # [177] DataValueTerm ::= iri | RDFLiteral | NumericLiteral | BooleanLiteral | QuotedTriple
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:DataValueTerm) do |input, data, callback|
      add_prod_datum :DataValueTerm, data.values.first
    end

    # [180] AnnotationPatternPath ::= '{|' PropertyListPathNotEmpty '|}'
    start_production(:AnnotationPatternPath) do |input, data, callback|
      data[:TriplesNode] = input[:TriplesNode]
    end

    #
    # Add `:TriplesNode` as subject of collected patterns
    # Input from `data` is `:pattern`.
    # Output to prod_data is `:pattern`.
    production(:AnnotationPatternPath) do |input, data, callback|
      add_prod_datum(:pattern, data[:pattern])
    end

    # [181] ExprQuotedTP ::= '<<' ExprVarOrTerm Verb ExprVarOrTerm '>>'
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ExprQuotedTP) do |input, data, callback|
      subject, object = data[:ExprVarOrTerm]
      predicate = data[:Verb]
      add_pattern(:ExprQuotedTP,
                  subject: subject,
                  predicate: predicate,
                  object: object,
                  quoted: true)
    end

    # [182] ExprVarOrTerm ::= iri | RDFLiteral | NumericLiteral | BooleanLiteral | Var | ExprQuotedTP
    #
    # Input from `data` is TODO.
    # Output to prod_data is TODO.
    production(:ExprVarOrTerm) do |input, data, callback|
      data.values.each {|v| add_prod_datum(:ExprVarOrTerm, v)}
    end

    ##
    # Initializes a new parser instance.
    #
    # @param  [String, IO, StringIO, #to_s]          input
    # @param  [Hash{Symbol => Object}] options
    # @option options [Boolean]  :all_vars (false)
    #   If `true`, emits on empty `project` operator when parsing `SELECT *`, which will emit all in-scope variables, rather than just those used in solutions.
    #   In the next minor release, the default for this option will change to `true`.
    # @option options [#to_s]    :anon_base     ("b0")
    #   Basis for generating anonymous Nodes
    # @option options [#to_s]    :base_uri     (nil)
    #   the base URI to use when resolving relative URIs (for acessing intermediate parser productions)
    # @option options [Logger, #write, #<<] :logger
    #   Record error/info/debug output
    # @option options [Hash]     :prefixes     (Hash.new)
    #   the prefix mappings to use (for acessing intermediate parser productions)
    # @option options [Boolean] :resolve_iris (false)
    #   Resolve prefix and relative IRIs, otherwise, when serializing the parsed SSE
    #   as S-Expressions, use the original prefixed and relative URIs along with `base` and `prefix`
    #   definitions.
    # @option options [Boolean]  :validate     (false)
    #   whether to validate the parsed statements and values
    # @yield  [parser] `self`
    # @yieldparam  [SPARQL::Grammar::Parser] parser
    # @yieldreturn [void] ignored
    # @return [SPARQL::Grammar::Parser]
    def initialize(input = nil, **options, &block)
      @input = case input
      when IO, StringIO then input.read
      else input.to_s.dup
      end
      @input.encode!(Encoding::UTF_8) if @input.respond_to?(:encode!)
      @options = {anon_base: "b0", validate: false}.merge(options)

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
    # @return [RDF::Queryable]
    # @see https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
    # @see https://axel.deri.ie/sparqltutorial/ESWC2007_SPARQL_Tutorial_unit2b.pdf
    def parse(prod = START)
      ll1_parse(@input,
        prod.to_sym,
        branch: BRANCH,
        first: FIRST,
        follow: FOLLOW,
        whitespace: WS,
        **@options
      )

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
          RDF::Query::Variable.new(id, distinguished: distinguished)
        end
      else
        unless distinguished
          # Allocate a non-distinguished variable identifier
          id = @nd_var_gen
          @nd_var_gen = id.succ
        end
        RDF::Query::Variable.new(id, distinguished: distinguished)
      end
    end

    # Create URIs
    def iri(value)
      # If we have a base URI, use that when constructing a new URI
      value = RDF::URI(value)
      if base_uri && value.relative?
        base_uri.join(value)
      else
        value
      end
    end

    def ns(prefix, suffix)
      base = prefix(prefix).to_s
      suffix = suffix.to_s.gsub(PN_LOCAL_ESC) {|esc| esc[1]} if
        suffix.to_s.match?(PN_LOCAL_ESC)
      suffix = suffix.to_s.sub(/^\#/, "") if base.index("#")
      debug {"ns(#{prefix.inspect}): base: '#{base}', suffix: '#{suffix}'"}
      iri(base + suffix.to_s)
    end

    # Create a literal
    def literal(value, **options)
      options = options.dup
      # Internal representation is to not use xsd:string, although it could arguably go the other way.
      options.delete(:datatype) if options[:datatype] == RDF::XSD.string
      debug("literal") do
        "value: #{value.inspect}, " +
        "options: #{options.inspect}, " +
        "validate: #{validate?.inspect}, "
      end
      RDF::Literal.new(value, validate: validate?, **options)
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
    # @param [Boolean] quoted For quoted triple
    # @param [Hash{Symbol => Object}] options
    def add_pattern(production, quoted: false, **options)
      progress(production, "[:pattern, #{options[:subject]}, #{options[:predicate]}, #{options[:object]}]")
      triple = {}
      triple[:quoted] = true if quoted
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

    ##
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
      extensions.each do |(var, _)|
        raise Error, "Extension variable #{var} also in SELECT" if vars.map(&:to_s).include?(var.to_s)
        vars << var
      end

      # If any extension contains an aggregate, and there is now group, implicitly group by 1
      if !data[:group] &&
         extensions.any? {|(_, function)| function.aggregate?} ||
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
            if avf = aggregates.detect {|(_, f)| f.equal?(function)}
              avf.first
            else
              # Allocate a temporary variable for this function, and retain the mapping for outside the group
              av = RDF::Query::Variable.new(".#{agg}", distinguished: false)
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

      # If SELECT * was used, emit a projection with empty variables, vs no projection at all. Only if :all_vars is true
      query = if vars == %i(*)
        options[:all_vars] ? SPARQL::Algebra::Expression[:project, [], query] : query
      elsif !vars.empty?
        SPARQL::Algebra::Expression[:project, vars, query]
      else
        query
      end

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
