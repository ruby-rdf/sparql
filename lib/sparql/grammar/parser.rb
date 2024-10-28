require 'ebnf'
require 'ebnf/peg/parser'
require 'sparql/grammar/meta'

module SPARQL::Grammar
  ##
  # A parser for the SPARQL 1.1 grammar.
  #
  # @see https://www.w3.org/TR/sparql11-query/#grammar
  # @see https://en.wikipedia.org/wiki/LR_parser
  class Parser
    include SPARQL::Grammar::Meta
    include SPARQL::Grammar::Terminals
    include EBNF::PEG::Parser

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
    # The internal representation of the result using hierarchy of RDF objects and SPARQL::Algebra::Operator
    # objects.
    # @return [Array]
    attr_accessor :result

    # Terminals passed to lexer. Order matters!
    terminal(:ANON,                 ANON) do |value, prod|
      bnode
    end
    terminal(:NIL,                  NIL) do |value, prod|
      RDF['nil']
    end
    terminal(:BLANK_NODE_LABEL,     BLANK_NODE_LABEL) do |value, prod|
      bnode(value[2..-1])
    end
    terminal(:IRIREF,               IRIREF) do |value, prod|
      begin
        iri(value[1..-2])
      rescue ArgumentError => e
        raise Error, e.message
      end
    end
    terminal(:DOUBLE_POSITIVE,      DOUBLE_POSITIVE) do |value, prod|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = value.sub(/\.([eE])/, '.0\1')
      literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL_POSITIVE,     DECIMAL_POSITIVE) do |value, prod|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = "0#{value}" if value[0,1] == "."
      literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER_POSITIVE,     INTEGER_POSITIVE) do |value, prod|
      literal(value, datatype: RDF::XSD.integer)
    end
    terminal(:DOUBLE_NEGATIVE,      DOUBLE_NEGATIVE) do |value, prod|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = value.sub(/\.([eE])/, '.0\1')
      literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL_NEGATIVE,     DECIMAL_NEGATIVE) do |value, prod|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = "0#{value}" if value[0,1] == "."
      literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER_NEGATIVE,     INTEGER_NEGATIVE) do |value, prod|
      literal(value, datatype: RDF::XSD.integer)
    end
    terminal(:DOUBLE,               DOUBLE) do |value, prod|
      # Note that a Turtle Double may begin with a '.[eE]', so tack on a leading
      # zero if necessary
      value = value.sub(/\.([eE])/, '.0\1')
      literal(value, datatype: RDF::XSD.double)
    end
    terminal(:DECIMAL,              DECIMAL) do |value, prod|
      # Note that a Turtle Decimal may begin with a '.', so tack on a leading
      # zero if necessary
      value = value
      #value = "0#{value}" if value[0,1] == "."
      literal(value, datatype: RDF::XSD.decimal)
    end
    terminal(:INTEGER,              INTEGER) do |value, prod|
      literal(value, datatype: RDF::XSD.integer)
    end
    terminal(:LANG_DIR,             LANG_DIR) do |value, prod|
      value[1..-1]
    end
    terminal(:PNAME_LN,             PNAME_LN, unescape: true) do |value, prod|
      prefix, suffix = value.split(":", 2)
      ns(prefix, suffix)
    end
    terminal(:PNAME_NS,             PNAME_NS) do |value, prod|
      value[0..-2].to_sym
    end
    terminal(:STRING_LITERAL_LONG1, STRING_LITERAL_LONG1, unescape: true) do |value, prod|
      value[3..-4]
    end
    terminal(:STRING_LITERAL_LONG2, STRING_LITERAL_LONG2, unescape: true) do |value, prod|
      value[3..-4]
    end
    terminal(:STRING_LITERAL1,      STRING_LITERAL1, unescape: true) do |value, prod|
      value[1..-2]
    end
    terminal(:STRING_LITERAL2,      STRING_LITERAL2, unescape: true) do |value, prod|
      value[1..-2]
    end
    terminal(:VAR1,                 VAR1) do |value, prod|
      variable(value[1..-1])
    end
    terminal(:VAR2,                 VAR2) do |value, prod|
      variable(value[1..-1])
    end

    # Productions

    # Query ::= Prologue ( SelectQuery | ConstructQuery | DescribeQuery | AskQuery )
    #
    # Inputs from value include :Prologe and :_Query_1
    # Result is query
    start_production(:Query, as_hash: true)
    production(:Query) do |value|
      query = value[:_Query_1]
      prologue = value[:Prologue] || {PrefixDecl: []}

      # Add prefix
      unless prologue[:PrefixDecl].empty?
        pfx = prologue[:PrefixDecl].shift
        prologue[:PrefixDecl].each {|p| pfx.merge!(p)}
        pfx.operands[1] = query
        query = pfx
      end

      # Add base
      query = SPARQL::Algebra::Expression[:base, prologue[:BaseDecl], query] if prologue[:BaseDecl]

      query
    end

    # UpdateUnit ::= Update
    #
    # Result is update
    start_production(:UpdateUnit, as_hash: true)
    production(:UpdateUnit) do |value|
      value[:Update]
    end

    # Prologue ::= ( BaseDecl | PrefixDecl )*
    #
    # Inputs from value include :BaseDecl and :PrefixDecl
    # Result is hash including BaseDecl and PrefixDecl
    production(:Prologue) do |value|
      unless resolve_iris?
        # Only output if we're not resolving URIs internally
        {
          BaseDecl: value.map {|v| v[:BaseDecl]}.compact.last,
          PrefixDecl: value.map {|v| v[:PrefixDecl]}.compact
        }.compact
      end
    end

    # BaseDecl ::= 'BASE' IRIREF
    #
    # Inputs from value includes :IRIREF
    # Result is hash including BaseDecl, unless we are resolving IRIs
    start_production(:BaseDecl, as_hash: true, insensitive_srings: :upper)
    production(:BaseDecl) do |value|
      iri = value[:IRIREF]
      debug("BaseDecl") {"Defined base as #{iri}"}
      self.base_uri = iri(iri)
      resolve_iris? || {BaseDecl: iri}
    end

    # PrefixDecl ::= 'PREFIX' PNAME_NS IRIREF
    #
    # Inputs from value include :PNAME_NS and :IRIREF
    # Result is hash including PrefixDecl
    start_production(:PrefixDecl, as_hash: true, insensitive_srings: :upper)
    production(:PrefixDecl) do |value|
      pfx = value[:PNAME_NS]
      self.prefix(pfx, value[:IRIREF])
      prefix_op = SPARQL::Algebra::Operator::Prefix.new([["#{pfx}:".to_sym, value[:IRIREF]]], [])
      {PrefixDecl: prefix_op}
    end

    # SelectQuery ::= SelectClause DatasetClause* WhereClause SolutionModifier ValuesClause
    #
    # Inputs are dataset, query, values, solution modifiers, vars, and extensions.
    # Result is a query
    start_production(:SelectQuery, as_hash: true)
    production(:SelectQuery) do |value|
      modifiers = {
        dataset: value[:_SelectQuery_1],
        query: value[:WhereClause][:query],
        values: value[:ValuesClause],
      }.merge(value[:SolutionModifier]).merge(value[:SelectClause])
      merge_modifiers(modifiers)
    end

    # SubSelect ::= SelectClause WhereClause SolutionModifier
    #
    # Inputs are query, solution modifiers, vars, and extensions.
    # Result is a hash including query.
    start_production(:SubSelect, as_hash: true)
    production(:SubSelect) do |value|
      modifiers = value[:WhereClause].merge(value[:SolutionModifier]).merge(value[:SelectClause])
      query = merge_modifiers(modifiers)
      {query: query}
    end

    # SelectClause ::= 'SELECT' ( 'DISTINCT' | 'REDUCED' )? ( ( Var | ( '(' Expression 'AS' Var ')' ) )+ | '*' )
    #
    #   (rule SelectClause (seq 'SELECT' _SelectClause_1 _SelectClause_2))
    #   (rule _SelectClause_1 (opt _SelectClause_3))
    #   (rule _SelectClause_3 (alt 'DISTINCT' 'REDUCED'))
    #   (rule _SelectClause_2 (alt _SelectClause_4 '*'))
    #   (rule _SelectClause_4 (plus _SelectClause_5))
    #   (rule _SelectClause_5 (alt Var _SelectClause_6))
    #   (rule _SelectClause_6 (seq '(' Expression 'AS' Var ')'))
    #
    # Inputs from value includes :_SelectClause_2 (a list of :variables and extensions).
    # Result is a hash including distinct/reduced, vars and extensions.
    start_production(:SelectClause, as_hash: true)
    production(:SelectClause) do |value|
      res = {
        DISTINCT_REDUCED: value[:_SelectClause_1]
      }

      sc2 = Array(value[:_SelectClause_2])
      sc2.each do |expr|
        if expr == '*'
          res[:Var] = %w(*)
        elsif expr.is_a?(RDF::Query::Variable)
          (res[:Var] ||= []) << expr
        elsif expr.is_a?(Hash) && expr[:extend]
          (res[:extend] ||= []) << expr[:extend]
        end
      end

      res
    end

    # (rule _SelectClause_6 (seq '(' Expression 'AS' Var ')'))
    start_production(:_SelectClause_6, as_hash: true)
    production(:_SelectClause_6) do |value|
      {extend: [value[:Var], value[:Expression]]}
    end

    #  ConstructQuery ::= 'CONSTRUCT'
    #                     ( ConstructTemplate
    #                       DatasetClause*
    #                       WhereClause
    #                       SolutionModifier | DatasetClause*
    #                       'WHERE' '{' TriplesTemplate? '}'
    #                       SolutionModifier
    #                     )
    #                     ValuesClause
    #
    #   (rule ConstructQuery (seq 'CONSTRUCT' _ConstructQuery_1 ValuesClause))
    #   (rule _ConstructQuery_1 (alt _ConstructQuery_2 _ConstructQuery_3))
    #   (rule _ConstructQuery_2
    #    (seq ConstructTemplate _ConstructQuery_4 WhereClause SolutionModifier))
    #   (rule _ConstructQuery_4 (star DatasetClause))
    #   (rule _ConstructQuery_3
    #    (seq _ConstructQuery_5 'WHERE' '{' _ConstructQuery_6 '}' SolutionModifier))
    #   (rule _ConstructQuery_5 (star DatasetClause))
    #   (rule _ConstructQuery_6 (opt TriplesTemplate))
    #
    # Inputs from value includes :_ConstructQuery_1 (query modifiers) and :ValuesClause.
    # Result is a query
    start_production(:ConstructQuery, as_hash: true)
    production(:ConstructQuery) do |value|
      modifiers = value[:_ConstructQuery_1].merge(values: value[:ValuesClause])
      template = modifiers.delete(:template) || []
      query = merge_modifiers(modifiers)
      SPARQL::Algebra::Expression[:construct, template, query]
    end

    # (rule _ConstructQuery_2
    #  (seq ConstructTemplate _ConstructQuery_4 WhereClause SolutionModifier))
    start_production(:_ConstructQuery_2,  as_hash: true)
    production(:_ConstructQuery_2) do |value|
      {
        template: value[:ConstructTemplate],
        dataset: value[:_ConstructQuery_4],
        query: value[:WhereClause][:query]
      }.merge(value[:SolutionModifier])
    end

    #   (rule _ConstructQuery_3
    #    (seq _ConstructQuery_5 'WHERE' '{' _ConstructQuery_6 '}'
    start_production(:_ConstructQuery_3, as_hash: true)
    production(:_ConstructQuery_3) do |value|
      {
        template: value[:_ConstructQuery_6],
        dataset: value[:_ConstructQuery_5],
        query: SPARQL::Algebra::Operator::BGP.new(*value[:_ConstructQuery_6])
      }.merge(value[:SolutionModifier])
    end
    
    # DescribeQuery ::= 'DESCRIBE' ( VarOrIri+ | '*' )
    #                   DatasetClause* WhereClause? SolutionModifier ValuesClause
    #
    # Inputs from value includes dataset, query, values, and other merge modifiers.
    # Result is a query
    start_production(:DescribeQuery, as_hash: true)
    production(:DescribeQuery) do |value|
      modifiers = {
        dataset: value[:_DescribeQuery_2],
        query: value&.dig(:_DescribeQuery_3, :query),
        values: value[:ValuesClause]
      }.merge(value[:SolutionModifier])
      query = merge_modifiers(modifiers)
      to_describe = Array(value[:_DescribeQuery_1]).reject {|v| v == '*'}
      SPARQL::Algebra::Expression[:describe, to_describe, query]
    end

    # AskQuery ::= 'ASK' DatasetClause* WhereClause ValuesClause
    #
    # Inputs from value includes dataset, query, values, and other merge modifiers.
    # Result is a query
    start_production(:AskQuery, as_hash: true)
    production(:AskQuery) do |value|
      modifiers = {
        dataset: value[:_AskQuery_1],
        query: value&.dig(:WhereClause, :query),
        values: value[:ValuesClause]
      }.merge(value[:SolutionModifier])
      SPARQL::Algebra::Operator::Ask.new(merge_modifiers(modifiers))
    end

    # DatasetClause ::= 'FROM' ( DefaultGraphClause | NamedGraphClause )
    start_production(:DatasetClause, as_hash: true, insenstive_strings: true)
    production(:DatasetClause) do |value|
      value[:_DatasetClause_1]
    end
    
    # DefaultGraphClause ::= SourceSelector
    #
    # Output is the source selector
    production(:DefaultGraphClause) do |value|
      value.first[:SourceSelector]
    end

    # NamedGraphClause ::= 'NAMED' SourceSelector
    #
    # Output is the named source selector.
    start_production(:NamedGraphClause, as_hash: true)
    production(:NamedGraphClause) do |value|
      [:named, value[:SourceSelector]]
    end

    # SourceSelector ::= iri
    production(:SourceSelector) do |value|
      value.first[:iri]
    end

    # WhereClause ::= 'WHERE'? GroupGraphPattern
    start_production(:WhereClause, as_hash: true)
    production(:WhereClause) do |value|
      {query: value&.dig(:GroupGraphPattern, :query)}
    end

    # SolutionModifier ::= GroupClause? HavingClause? OrderClause? LimitOffsetClauses?
    #
    # Result is a query modifier including group, having, order, and slice.
    start_production(:SolutionModifier, as_hash: true)
    production(:SolutionModifier) do |value|
      {
        group: value[:_SolutionModifier_1],
        having: value[:_SolutionModifier_2],
        order: value[:_SolutionModifier_3],
        slice: value[:_SolutionModifier_4],
      }
    end

    # GroupClause ::= 'GROUP' 'BY' GroupCondition+
    #
    # Returns one or more group conditions
    start_production(:GroupClause, as_hash: true)
    production(:GroupClause) do |value|
      value[:_GroupClause_1]
    end

    # GroupCondition ::= BuiltInCall | FunctionCall
    #                  | '(' Expression ( 'AS' Var )? ')' | Var
    #
    #   (rule GroupCondition (alt BuiltInCall FunctionCall _GroupCondition_1 Var))
    #   (rule _GroupCondition_1 (seq '(' Expression _GroupCondition_2 ')'))
    #   (rule _GroupCondition_2 (opt _GroupCondition_3))
    #   (rule _GroupCondition_3 (seq 'AS' Var))
    #   
    # Result is an expression
    start_production(:GroupCondition, as_hash: true)
    production(:GroupCondition) do |value|
      value
    end

    # _GroupCondition_1 ::= '(' Expression ( 'AS' Var )? ')'
    #
    #   (rule _GroupCondition_1 (seq '(' Expression _GroupCondition_2 ')'))
    #   (rule _GroupCondition_2 (opt _GroupCondition_3))
    #   (rule _GroupCondition_3 (seq 'AS' Var))
    #
    # Returns the expression, or an array of the var and expression.
    start_production(:_GroupCondition_1, as_hash: true)
    production(:_GroupCondition_1) do |value|
      if value[:_GroupCondition_2]
        [value[:_GroupCondition_2], value[:Expression]]
      else
        value[:Expression]
      end
    end

    production(:_GroupCondition_3) {|value| value.last[:Var]}

    # HavingClause ::= 'HAVING' HavingCondition+
    #
    #   (rule HavingClause (seq 'HAVING' _HavingClause_1))
    #   (rule _HavingClause_1 (plus HavingCondition))
    start_production(:HavingClause, as_hash: true)
    production(:HavingClause) do |value|
      value[:_HavingClause_1]
    end

    # HavingCondition ::= Constraint
    start_production(:HavingCondition, as_hash: true)
    production(:HavingCondition) do |value|
      value[:Constraint]
    end
    
    # OrderClause ::= 'ORDER' 'BY' OrderCondition+
    start_production(:OrderClause, as_hash: true)
    production(:OrderClause) do |value|
      value[:_OrderClause_1]
    end

    # OrderCondition ::= ( ( 'ASC' | 'DESC' ) BrackettedExpression ) | ( Constraint | Var )
    #
    #   (rule OrderCondition (alt _OrderCondition_1 _OrderCondition_2))
    #   (rule _OrderCondition_1 (seq _OrderCondition_3 BrackettedExpression))
    #   (rule _OrderCondition_3 (alt 'ASC' 'DESC'))
    #   (rule _OrderCondition_2 (alt Constraint Var))
    start_production(:OrderCondition, as_hash: true)
    production(:OrderCondition) do |value|
      if value.is_a?(Hash) && value[:_OrderCondition_3]
        SPARQL::Algebra::Expression(value[:_OrderCondition_3].downcase, value[:BrackettedExpression])
      else
        value
      end
    end
    start_production(:_OrderCondition_1, as_hash: true)

    # LimitOffsetClauses ::= LimitClause OffsetClause? | OffsetClause LimitClause?
    #
    #   (rule _LimitOffsetClauses_1 (seq LimitClause _LimitOffsetClauses_3))
    #   (rule _LimitOffsetClauses_3 (opt OffsetClause))
    #   (rule _LimitOffsetClauses_2 (seq OffsetClause _LimitOffsetClauses_4))
    #   (rule _LimitOffsetClauses_4 (opt LimitClause))
    production(:LimitOffsetClauses) do |value|
      if value[:LimitClause]
        if value[:_LimitOffsetClauses_3]
          [value[:_LimitOffsetClauses_3], value[:LimitClause]]
        else
          [:_, value[:LimitClause]]
        end
      else
        if value[:_LimitOffsetClauses_4]
          [value[:OffsetClause], value[:_LimitOffsetClauses_4]]
        else
          [value[:OffsetClause], :_]
        end
      end
    end
    start_production(:_LimitOffsetClauses_1, as_hash: true)
    start_production(:_LimitOffsetClauses_2, as_hash: true)

    # LimitClause ::= 'LIMIT' INTEGER
    start_production(:LimitClause, as_hash: true)
    production(:LimitClause) do |value|
      value[:INTEGER]
    end

    # OffsetClause ::= 'OFFSET' INTEGER
    start_production(:OffsetClause, as_hash: true)
    production(:OffsetClause) do |value|
      value[:INTEGER]
    end

    # ValuesClause ::= ( 'VALUES' DataBlock )?
    #
    # Result is a table operator
    start_production(:ValuesClause, as_hash: true)
    production(:ValuesClause) do |value|
      debug("ValuesClause") {value.inspect}
      if value
        args = [Array(value[:DataBlock][:Var]).unshift(:vars)] + value[:DataBlock][:row]
        table = SPARQL::Algebra::Expression.for(:table, *args)
        table
      end
    end

    # Update ::= Prologue (Update1 (";" Update)? )?
    #
    #   (rule Update (seq Prologue _Update_1))
    #   (rule _Update_1 (opt _Update_2))
    #   (rule _Update_2 (seq Update1 _Update_3))
    #   (rule _Update_3 (opt _Update_4))
    #   (rule _Update_4 (seq ';' Update))
    #
    # Output is algebra Expression
    start_production(:Update, as_hash: true)
    production(:Update) do |value|
      prologue = value[:Prologue] || {PrefixDecl: []}
      update = value[:_Update_1] || SPARQL::Algebra::Expression(:update)

      # Add prefix
      unless prologue[:PrefixDecl].empty?
        pfx = prologue[:PrefixDecl].shift
        prologue[:PrefixDecl].each {|p| pfx.merge!(p)}
        pfx.operands[1] = update
        update = pfx
      end

      # Add base
      update = SPARQL::Algebra::Expression[:base, prologue[:BaseDecl], update] if prologue[:BaseDecl]
      update
    end

    #   (rule _Update_2 (seq Update1 _Update_3))
    #
    # Merges update operators
    #
    # Returns an update operator
    start_production(:_Update_2, as_hash: true)
    production(:_Update_2) do |value|
      if value[:_Update_3]
        SPARQL::Algebra::Expression(:update, *(value[:Update1].operands + value[:_Update_3].operands))
      else
        value[:Update1]
      end
    end

    #   (rule _Update_4 (seq ';' Update))
    production(:_Update_4) do |value|
      value.last[:Update]
    end

    # Update1 ::= Load | Clear | Drop | Add | Move | Copy
    #           | Create | InsertData | DeleteData | DeleteWhere | Modify
    #
    # Output is SSE `(update ...)`
    production(:Update1) do |value|
      SPARQL::Algebra::Expression.for(:update, value)
    end

    # Load ::= "LOAD" "SILENT"? iri ("INTO" GraphRef)?
    #
    #   (rule Load (seq 'LOAD' _Load_1 iri _Load_2))
    #   (rule _Load_1 (opt 'SILENT'))
    #   (rule _Load_2 (opt _Load_3))
    #   (rule _Load_3 (seq 'INTO' GraphRef))
    start_production(:Load, as_hash: true)
    production(:Load) do |value|
      args = []
      args << :silent if value[:_Load_1]
      args << value[:iri]
      args << value[:_Load_2].last[:GraphRef] if value[:_Load_2]
      SPARQL::Algebra::Expression(:load, *args)
    end

    # Clear ::= "CLEAR" "SILENT"? GraphRefAll
    start_production(:Clear, as_hash: true)
    production(:Clear) do |value|
      args = []
      args << :silent if value[:_Clear_1]
      args << (value[:GraphRefAll].is_a?(String) ? value[:GraphRefAll].downcase.to_sym : value[:GraphRefAll])
      SPARQL::Algebra::Expression(:clear, *args)
    end

    # Drop ::= "DROP" "SILENT"? GraphRefAll
    start_production(:Drop, as_hash: true)
    production(:Drop) do |value|
      args = []
      args << :silent if value[:_Drop_1]
      args << (value[:GraphRefAll].is_a?(String) ? value[:GraphRefAll].downcase.to_sym : value[:GraphRefAll])
      SPARQL::Algebra::Expression(:drop, *args)
    end

    # Create ::= "CREATE" "SILENT"? GraphRef
    start_production(:Create, as_hash: true)
    production(:Create) do |value|
      args = []
      args << :silent if value[:_Create_1]
      args << (value[:GraphRef].is_a?(String) ? value[:GraphRef].downcase.to_sym : value[:GraphRef])
      SPARQL::Algebra::Expression(:create, *args)
    end

    # Add ::= "ADD" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    #
    # Input is `GraphOrDefault` and optionally `:silent`.
    # Output is an `Operator::Add` object.
    production(:Add) do |value|
      args = []
      args << :silent if value[1][:_Add_1]
      args << value[2][:GraphOrDefault]
      args << value[4][:GraphOrDefault]
      SPARQL::Algebra::Expression(:add, *args)
    end

    # Move ::= "MOVE" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    production(:Move) do |value|
      args = []
      args << :silent if value[1][:_Move_1]
      args << value[2][:GraphOrDefault]
      args << value[4][:GraphOrDefault]
      SPARQL::Algebra::Expression(:move, *args)
    end

    # Copy ::= "COPY" "SILENT"? GraphOrDefault "TO" GraphOrDefault
    production(:Copy) do |value|
      args = []
      args << :silent if value[1][:_Copy_1]
      args << value[2][:GraphOrDefault]
      args << value[4][:GraphOrDefault]
      SPARQL::Algebra::Expression(:copy, *args)
    end

    # InsertData ::= "INSERT DATA" QuadData
    #
    # Freeze existing bnodes, so that if an attempt is made to re-use such a node, and error is raised
    #
    # Returns (insertData ...)
    start_production(:InsertData, as_hash: true)
    production(:InsertData) do |value|
      SPARQL::Algebra::Expression(:insertData, value[:QuadData])
    end

    # DeleteData ::= "DELETE DATA" QuadData
    # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
    start_production(:DeleteData, as_hash: true)
    production(:DeleteData) do |value|
      raise Error, "DeleteData contains BNode operands: #{value[:QuadData].to_sse}" if Array(value[:QuadData]).any?(&:node?)
      SPARQL::Algebra::Expression(:deleteData, value[:QuadData])
    end

    # DeleteWhere ::= "DELETE WHERE" QuadPattern
    # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
    start_production(:DeleteWhere, as_hash: true)
    production(:DeleteWhere) do |value|
      raise Error, "DeleteWhere contains BNode operands: #{value[:QuadPattern].to_sse}" if Array(value[:QuadPattern]).any?(&:node?)
      SPARQL::Algebra::Expression(:deleteWhere, Array(value[:QuadPattern]))
    end

    #
    # Modify::= ( 'WITH' iri )? ( DeleteClause InsertClause? | InsertClause ) UsingClause* 'WHERE' GroupGraphPattern
    #
    #   (rule Modify (seq _Modify_1 _Modify_2 _Modify_3 'WHERE' GroupGraphPattern))
    #   (rule _Modify_1 (opt _Modify_4))
    #   (rule _Modify_4 (seq 'WITH' iri))
    #   (rule _Modify_2 (alt _Modify_5 InsertClause))
    #   (rule _Modify_5 (seq DeleteClause _Modify_6))
    #   (rule _Modify_6 (opt InsertClause))
    #   (rule _Modify_3 (star UsingClause))
    #
    # Returns modify operand
    start_production(:Modify, as_hash: true)
    production(:Modify) do |value|
      query = value&.dig(:GroupGraphPattern, :query)
      query = SPARQL::Algebra::Expression.for(:using, value[:_Modify_3], query) unless value[:_Modify_3].empty?
      operands = [query, *Array(value[:_Modify_2])].compact
      operands = [SPARQL::Algebra::Expression.for(:with, value[:_Modify_1], *operands)] if value[:_Modify_1]
      SPARQL::Algebra::Expression(:modify, *operands)
    end

    #   (rule _Modify_2 (alt _Modify_5 InsertClause))
    #
    # Clear cached bnodes here to be able to detect illegal attempt to re-define
    #
    # XXX Doe we really need to clear the cache?
    start_production(:_Modify_2) {self.clear_bnode_cache}

    #   (rule _Modify_4 (seq 'WITH' iri))
    production(:_Modify_4) do |value|
      value.last[:iri]
    end

    #   (rule _Modify_5 (seq DeleteClause _Modify_6))
    start_production(:_Modify_5, as_hash: true)
    production(:_Modify_5) do |value|
      [value[:DeleteClause], value[:_Modify_6]]
    end

    # DeleteClause ::= "DELETE" QuadPattern
    #
    # Generate BNodes instead of non-distinguished variables. BNodes are not legal, but this will generate them rather than non-distinguished variables so they can be detected.
    start_production(:DeleteClause, as_hash: true)
    production(:DeleteClause) do |value|
      raise Error, "DeleteClause contains BNode operands: #{Array(value[:QuadPattern]).to_sse}" if Array(value[:QuadPattern]).any?(&:node?)
      SPARQL::Algebra::Expression(:delete, Array(value[:QuadPattern]))
    end

    # InsertClause ::= "INSERT" QuadPattern
    #
    # Generate BNodes instead of non-distinguished variables.
    start_production(:InsertClause, as_hash: true)
    production(:InsertClause) do |value|
      SPARQL::Algebra::Expression(:insert, Array(value[:QuadPattern]))
    end

    # UsingClause ::= "USING" ( iri | "NAMED" iri)
    #
    #   (rule UsingClause (seq 'USING' _UsingClause_1))
    #   (rule _UsingClause_1 (alt iri _UsingClause_2))
    #   (rule _UsingClause_2 (seq 'NAMED' iri))
    #
    start_production(:UsingClause, as_hash: true)
    production(:UsingClause) do |value|
      value[:_UsingClause_1]
    end

    # (rule _UsingClause_2 (seq 'NAMED' iri))
    start_production(:_UsingClause_2, as_hash: true)
    production(:_UsingClause_2) do |value|
      [:named, value[:iri]]
    end

    # GraphOrDefault ::= "DEFAULT" | "GRAPH"? iri
    #
    #   (rule GraphOrDefault (alt 'DEFAULT' _GraphOrDefault_1))
    #   (rule _GraphOrDefault_1 (seq _GraphOrDefault_2 iri))
    #   (rule _GraphOrDefault_2 (opt 'GRAPH'))
    production(:GraphOrDefault) do |value|
      value.is_a?(String) ? value.downcase.to_sym : value
    end
    start_production(:_GraphOrDefault_1, as_hash: true)
    production(:_GraphOrDefault_1) {|value| value[:iri]}

    # GraphRef ::= "GRAPH" iri
    production(:GraphRef) do |value|
      value.last[:iri]
    end

    # QuadPattern::= '{' Quads '}'
    # Returns array of patterns
    start_production(:QuadPattern, as_hash: true) {self.gen_bnodes}
    production(:QuadPattern) do |value|
      self.gen_bnodes(false)
      value[:Quads]
    end

    # QuadData ::= "{" Quads "}"
    #
    # QuadData is like QuadPattern, except without BNodes
    # Generate BNodes instead of non-distinguished variables
    #
    # Returns array of patterns
    start_production(:QuadData, as_hash: true) do |data|
      # Freeze bnodes if called from INSERT DATA
      self.freeze_bnodes if data[:_rept_data].first.key?(:"INSERT DATA")
      self.gen_bnodes
    end
    production(:QuadData) do |value|
      # Transform using statements instead of patterns, and verify there are no variables
      raise Error, "QuadData contains variable operands: #{Array(value[:Quads]).to_sse}" if Array(value[:Quads]).any?(&:variable?)
      self.gen_bnodes(false)
      value[:Quads]
    end

    # Quads ::= TriplesTemplate? ( QuadsNotTriples '.'? TriplesTemplate? )*
    #
    #   (rule Quads (seq _Quads_1 _Quads_2))
    #   (rule _Quads_1 (opt TriplesTemplate))
    #   (rule _Quads_2 (star _Quads_3))
    #   (rule _Quads_3 (seq QuadsNotTriples _Quads_4 _Quads_5))
    #   (rule _Quads_4 (opt '.'))
    #   (rule _Quads_5 (opt TriplesTemplate))
    #
    # Returns an array of patterns
    start_production(:Quads, as_hash: true)
    production(:Quads) do |value|
      Array(value[:_Quads_1]) + value[:_Quads_2].flatten
    end

    #   (rule _Quads_3 (seq QuadsNotTriples _Quads_4 _Quads_5))
    start_production(:_Quads_3, as_hash: true)
    production(:_Quads_3) do |value|
       [value[:QuadsNotTriples]] + Array(value[:_Quads_5])
    end

    # QuadsNotTriples ::= "GRAPH" VarOrIri "{" TriplesTemplate? "}"
    #
    #   (rule QuadsNotTriples (seq 'GRAPH' VarOrIri '{' _QuadsNotTriples_1 '}'))
    #   (rule _QuadsNotTriples_1 (opt TriplesTemplate))
    #
    # Result is Graph operator
    start_production(:QuadsNotTriples, as_hash: true)
    production(:QuadsNotTriples) do |value|
      SPARQL::Algebra::Expression.for(:graph, value[:VarOrIri], Array(value[:_QuadsNotTriples_1]))
    end

    # TriplesTemplate ::= TriplesSameSubject ("." TriplesTemplate? )?
    #
    #   (rule TriplesTemplate (seq TriplesSameSubject _TriplesTemplate_1))
    #   (rule _TriplesTemplate_1 (opt _TriplesTemplate_2))
    #   (rule _TriplesTemplate_2 (seq '.' _TriplesTemplate_3))
    #   (rule _TriplesTemplate_3 (opt TriplesTemplate))
    #
    # Returnes patterns
    start_production(:TriplesTemplate, as_hash: true)
    production(:TriplesTemplate) do |value|
      value[:TriplesSameSubject] + Array(value[:_TriplesTemplate_1])
    end
    
    #   (rule _TriplesTemplate_2 (seq '.' _TriplesTemplate_3))
    production(:_TriplesTemplate_2) do |value|
      value.last[:_TriplesTemplate_3]
    end

    # GroupGraphPattern ::= '{' ( SubSelect | GroupGraphPatternSub ) '}'
    start_production(:GroupGraphPattern, as_hash: true)
    production(:GroupGraphPattern) do |value|
      {query: value&.dig(:_GroupGraphPattern_1, :query)}
    end

    # GroupGraphPatternSub ::= TriplesBlock? (GraphPatternNotTriples "."? TriplesBlock? )*
    #
    #   (rule GroupGraphPatternSub (seq _GroupGraphPatternSub_1 _GroupGraphPatternSub_2))
    #   (rule _GroupGraphPatternSub_1 (opt TriplesBlock))
    #   (rule _GroupGraphPatternSub_2 (star _GroupGraphPatternSub_3))
    #   (rule _GroupGraphPatternSub_3
    #    (seq GraphPatternNotTriples _GroupGraphPatternSub_4 _GroupGraphPatternSub_5))
    #   (rule _GroupGraphPatternSub_4 (opt '.'))
    #   (rule _GroupGraphPatternSub_5 (opt TriplesBlock))
    start_production(:GroupGraphPatternSub, as_hash: true)
    production(:GroupGraphPatternSub) do |value|
      query = value[:_GroupGraphPatternSub_1] || SPARQL::Algebra::Operator::BGP.new
      extensions = []
      filters = []

      value[:_GroupGraphPatternSub_2].each do |ggps2|
        filters << ggps2[:filter] if ggps2[:filter]

        bgp = ggps2[:query]
        query = if bgp && query.mergable?(bgp) && false # XXX No agressive merging
          query.merge(bgp)
        elsif query.empty? && bgp
          bgp
        elsif !bgp || bgp.empty?
          query
        else
          SPARQL::Algebra::Operator::Join.new(query, bgp)
        end

        # Extensions
        if ggps2[:extend]
          # Extensions will be an array of pairs of variable and expression
          error(nil,
                "Internal error on extensions form",
                production: :GroupGraphPatternSub,
                fatal: true) unless
            ggps2[:extend].is_a?(Array) && ggps2[:extend].all? {|e| e.is_a?(Array)}

          # The variable assigned in a BIND clause must not be already in-use within the immediately preceding TriplesBlock within a GroupGraphPattern.
          # None of the variables on the lhs of data[:extend] may be used in lhs
          ggps2[:extend].each do |(v, _)|
            error(nil, "BIND Variable #{v} used in pattern", production: :GraphPatternNotTriples) if query.vars.map(&:to_sym).include?(v.to_sym)
          end
          query = if query.is_a?(SPARQL::Algebra::Operator::Extend)
            # Coalesce extensions
            lhs = query.dup
            lhs.operands.first.concat(ggps2[:extend])
            lhs
          else
            SPARQL::Algebra::Expression[:extend, ggps2[:extend], query] unless ggps2[:extend].empty?
          end
        end

        # _GroupGraphPatternSub_3 can return patterns from TriplesBlock?
        if bgp = ggps2[:extra]
          query = if query.mergable?(bgp) && false # XXX No agressive merging
            query.merge(bgp)
          elsif query.empty?
            bgp
          elsif bgp.empty?
            query
          elsif bgp.is_a?(SPARQL::Algebra::Operator::Path)
            SPARQL::Algebra::Operator::Sequence.new(query, bgp)
          else
            SPARQL::Algebra::Operator::Join.new(query, bgp)
          end
        end

        query = if ggps2[:leftjoin]
          SPARQL::Algebra::Expression.for(:leftjoin, query, *ggps2[:leftjoin])
        elsif ggps2[:minus]
          SPARQL::Algebra::Expression.for(:minus, query, ggps2[:minus])
        else
          query
        end
      end

      # Filters
      unless filters.empty?
        expr = filters.length > 1 ? SPARQL::Algebra::Operator::Exprlist.new(*filters) : filters.first
        query = SPARQL::Algebra::Operator::Filter.new(expr, query)
      end

      {query: query}
    end

    # (rule _GroupGraphPatternSub_3
    #   (seq GraphPatternNotTriples _GroupGraphPatternSub_4 _GroupGraphPatternSub_5))
    start_production(:_GroupGraphPatternSub_3, as_hash: true)
    production(:_GroupGraphPatternSub_3) do |value|
      {
        extend: value&.dig(:GraphPatternNotTriples, :extend),
        extra: value[:_GroupGraphPatternSub_5],
        filter: value&.dig(:GraphPatternNotTriples, :filter),
        leftjoin: value&.dig(:GraphPatternNotTriples, :leftjoin),
        minus: value&.dig(:GraphPatternNotTriples, :minus),
        query: value&.dig(:GraphPatternNotTriples, :query),
      }
    end

    # TriplesBlock ::= TriplesSameSubjectPath
    #                  ( '.' TriplesBlock? )?
    #
    #   (rule TriplesBlock (seq TriplesSameSubjectPath _TriplesBlock_1))
    #   (rule _TriplesBlock_1 (opt _TriplesBlock_2))
    #   (rule _TriplesBlock_2 (seq '.' _TriplesBlock_3))
    #   (rule _TriplesBlock_3 (opt TriplesBlock))
    start_production(:TriplesBlock, as_hash: true)
    production(:TriplesBlock) do |value|
      tb1 = value[:_TriplesBlock_1]
      sequence = Array(value[:TriplesSameSubjectPath])

      # Append triples from ('.' TriplesBlock? )?
      if tb1.is_a?(SPARQL::Algebra::Operator::Sequence)
        tb1.operands.each do |op|
          sequence += op.respond_to?(:patterns) ? op.patterns : [op]
        end
      elsif tb1.respond_to?(:patterns)
        sequence += tb1.patterns
      elsif tb1
        sequence << tb1
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
          new_seq << SPARQL::Algebra::Operator::BGP.new(*patterns) unless patterns.empty?
          patterns = []
          new_seq << element
        end
      end
      new_seq << SPARQL::Algebra::Operator::BGP.new(*patterns) unless patterns.empty?

      # Optionally create a sequence, if there are enough gathered.
      # FIXME: Join?
      if new_seq.length > 1
        if new_seq.any? {|e| e.is_a?(SPARQL::Algebra::Operator::Path)}
          SPARQL::Algebra::Expression.for(:sequence, *new_seq)
        else
          SPARQL::Algebra::Expression.for(:join, *new_seq)
        end
      else
        new_seq.first
      end
    end

    #   (rule _TriplesBlock_2 (seq '.' _TriplesBlock_3))
    start_production(:_TriplesBlock_2, as_hash: true)
    production(:_TriplesBlock_2) do |value|
      value[:_TriplesBlock_3]
    end

    # ReifiedTripleBlock ::= ReifiedTriple PropertyList
    start_production(:ReifiedTripleBlock, as_hash: true)
    production(:ReifiedTripleBlock) do |value|
      {ReifiedTripleBlock: value[:ReifiedTriple][:pattern] + Array(value[:PropertyList])}
    end

    # ReifiedTripleBlockPath ::= ReifiedTriple PropertyListPath
    #
    # Returns `{ReifiedTripleBlockPath: patterns}`
    start_production(:ReifiedTripleBlockPath, as_hash: true)
    production(:ReifiedTripleBlockPath) do |value|
      {ReifiedTripleBlockPath: value[:ReifiedTriple][:pattern] + Array(value[:PropertyListPath])}
    end

    # OptionalGraphPattern ::= 'OPTIONAL' GroupGraphPattern
    #
    # FIXME: This should not extract a filter if there is more than one level of curly braces.
    start_production(:OptionalGraphPattern, as_hash: true)
    production(:OptionalGraphPattern) do |value|
      query = value&.dig(:GroupGraphPattern, :query) || SPARQL::Algebra::Operator::BGP.new
      if query.is_a?(SPARQL::Algebra::Operator::Filter)
        # Change to expression on left-join with query element
        expr, query = query.operands
        {leftjoin: [query, expr]}
      elsif !query.empty?
        {leftjoin: [query]}
      end
    end

    # GraphGraphPattern ::= 'GRAPH' VarOrIri GroupGraphPattern
    start_production(:GraphGraphPattern, as_hash: true)
    production(:GraphGraphPattern) do |value|
      name = value[:VarOrIri]
      bgp = value&.dig(:GroupGraphPattern, :query) || SPARQL::Algebra::Operator::BGP.new
      {
        query: (name ? SPARQL::Algebra::Expression.for(:graph, name, bgp) : bgp)
      }
    end

    # ServiceGraphPattern ::= 'SERVICE' 'SILENT'? VarOrIri GroupGraphPattern
    start_production(:ServiceGraphPattern, as_hash: true)
    production(:ServiceGraphPattern) do |value|
      query = value&.dig(:GroupGraphPattern, :query) || SPARQL::Algebra::Operator::BGP.new
      args = []
      args << :silent if value[:_ServiceGraphPattern_1]
      args << value[:VarOrIri]
      args << query
      service = SPARQL::Algebra::Expression.for(:service, *args)
      {query: service}
    end

    # Bind ::= 'BIND' '(' Expression 'AS' Var ')'
    start_production(:Bind, as_hash: true)
    production(:Bind) do |value|
      {extend: [[value[:Var], value[:Expression]]]}
    end

    # InlineData ::= 'VALUES' DataBlock
    start_production(:InlineData, as_hash: true)
    production(:InlineData) do |value|
      debug("InlineData") {value[:DataBlock].inspect}
      args = [Array(value[:DataBlock][:Var]).unshift(:vars)] + value[:DataBlock][:row]
      table = SPARQL::Algebra::Expression.for(:table, *args)
      {query: table}
    end

    # InlineDataOneVar ::= Var '{' DataBlockValue* '}'
    start_production(:InlineDataOneVar, as_hash: true)
    production(:InlineDataOneVar) do |value|
      {
        Var: value[:Var],
        row: value[:_InlineDataOneVar_1].map {|dbv| [:row, [value[:Var], dbv]]}
      }
    end

    # InlineDataFull ::= ( NIL | '(' Var* ')' )
    #                    '{' ( '(' DataBlockValue* ')' | NIL )* '}'
    #
    #   (rule InlineDataFull (seq _InlineDataFull_1 '{' _InlineDataFull_2 '}'))
    #   (rule _InlineDataFull_1 (alt NIL _InlineDataFull_3))
    #   (rule _InlineDataFull_3 (seq '(' _InlineDataFull_4 ')'))
    #   (rule _InlineDataFull_4 (star Var))
    #   (rule _InlineDataFull_2 (star _InlineDataFull_5))
    #   (rule _InlineDataFull_5 (alt _InlineDataFull_6 NIL))
    #   (rule _InlineDataFull_6 (seq '(' _InlineDataFull_7 ')'))
    #   (rule _InlineDataFull_7 (star DataBlockValue))
    #
    start_production(:InlineDataFull, as_hash: true)
    production(:InlineDataFull) do |value|
      vars = value[:_InlineDataFull_1]
      vars = [] if vars == RDF.nil

      rows = value[:_InlineDataFull_2].map do |ds|
        # XXX what if ds == RDF.nil
        if ds.length < vars.length
          raise Error, "Too few values in a VALUE clause compared to the number of variables"
        elsif ds.length > vars.length
          raise Error, "Too many values in a VALUE clause compared to the number of variables"
        end
        r = [:row]
        ds.each_with_index do |d, i|
          r << [vars[i], d] if d
        end
        r unless r.empty?
      end.compact

      {
        Var: vars,
        row: rows
      }
    end

    # (rule _InlineDataFull_3 (seq '(' _InlineDataFull_4 ')'))
    start_production(:_InlineDataFull_3, as_hash: true)
    production(:_InlineDataFull_3) do |value|
      value[:_InlineDataFull_4]
    end

    # (rule _InlineDataFull_6 (seq '(' _InlineDataFull_7 ')'))
    start_production(:_InlineDataFull_6, as_hash: true)
    production(:_InlineDataFull_6) do |value|
      value[:_InlineDataFull_7]
    end

    # Reifier ::= '~' VarOrReifierId?
    #
    # Beginning the reifier production, the curReifier is taken from the reifier term constructor. Then yield the the RDF triple curReifier rdf:reifies curTripleTerm.
    #
    # Returns emitted pattern
    start_production(:Reifier, as_hash: true)
    production(:Reifier) do |value|
      rid = prod_data[:curReifier] = value[:_Reifier_1] || bnode
      RDF::Query::Pattern.new(rid, RDF.reifies, prod_data[:TripleTerm]) if prod_data[:TripleTerm]
    end

    # MinusGraphPattern ::= 'MINUS' GroupGraphPattern
    start_production(:MinusGraphPattern, as_hash: true)
    production(:MinusGraphPattern) do |value|
      query = value&.dig(:GroupGraphPattern, :query) || SPARQL::Algebra::Operator::BGP.new
      {minus: query}
    end

    # GroupOrUnionGraphPattern ::= GroupGraphPattern
    #                              ( 'UNION' GroupGraphPattern )*
    start_production(:GroupOrUnionGraphPattern, as_hash: true)
    production(:GroupOrUnionGraphPattern) do |value|
      lhs = value&.dig(:GroupGraphPattern, :query)
      query = value[:_GroupOrUnionGraphPattern_1].reduce(lhs) do |memo, q|
        SPARQL::Algebra::Expression.for(:union, memo, q)
      end

      {query: query}
    end

    # (rule _GroupOrUnionGraphPattern_2 (seq 'UNION' GroupGraphPattern))
    start_production(:_GroupOrUnionGraphPattern_2, as_hash: true)
    production(:_GroupOrUnionGraphPattern_2) do |value|
      value&.dig(:GroupGraphPattern, :query)
    end

    # Filter ::= 'FILTER' Constraint
    start_production(:Filter, as_hash: true)
    production(:Filter) do |value|
      {filter: value[:Constraint]}
    end

    # FunctionCall ::= iri ArgList
    start_production(:FunctionCall, as_hash: true)
    production(:FunctionCall) do |value|
      SPARQL::Algebra::Operator::FunctionCall.new(value[:iri], *value[:ArgList])
    end

    # ArgList ::= NIL | '(' 'DISTINCT'? Expression ( ',' Expression )* ')'
    #
    #   (rule ArgList (alt NIL _ArgList_1))
    #   (rule _ArgList_1 (seq '(' _ArgList_2 Expression _ArgList_3 ')'))
    #   (rule _ArgList_2 (opt 'DISTINCT'))
    #   (rule _ArgList_3 (star _ArgList_4))
    #   (rule _ArgList_4 (seq ',' Expression))
    #
    # XXX handle DISTINCT?
    production(:ArgList) do |value|
      Array(value)
    end

    start_production(:_ArgList_1, as_hash: true)
    production(:_ArgList_1) do |value|
      value[:_ArgList_3].unshift(value[:Expression])
    end

    start_production(:_ArgList_4, as_hash: true)
    production(:_ArgList_4) do |value|
      value[:Expression]
    end

    # ExpressionList ::= NIL | '(' Expression ( ',' Expression )* ')'
    #
    #   (rule ExpressionList (alt NIL _ExpressionList_1))
    production(:ExpressionList) do |value|
      value.is_a?(RDF::Term) ? [] : value.flatten
    end

    #   (rule _ExpressionList_1 (seq '(' Expression _ExpressionList_2 ')'))
    production(:_ExpressionList_1) do |value|
      [value[1][:Expression], value[2][:_ExpressionList_2]].compact
    end

    #   (rule _ExpressionList_2 (star _ExpressionList_3))
    #   (rule _ExpressionList_3 (seq ',' Expression))
    production(:_ExpressionList_2) do |value|
      value.map {|el3| el3.last[:Expression]}
    end

    # ConstructTemplate ::= '{' ConstructTriples? '}'
    start_production(:ConstructTemplate, as_hash: true)
    production(:ConstructTemplate) do |value|
      # Generate BNodes instead of non-distinguished variables
      self.gen_bnodes(false)
      value[:_ConstructTemplate_1]
    end

    # ConstructTriples  ::= TriplesSameSubject ( '.' ConstructTriples? )?
    # Returns patterns
    start_production(:ConstructTriples, as_hash: true) do
      # Generate BNodes instead of non-distinguished variables
      self.gen_bnodes
    end
    production(:ConstructTriples) do |value|
      # Generate BNodes instead of non-distinguished variables
      value[:TriplesSameSubject] + Array(value[:_ConstructTriples_1])
    end

    # (rule _ConstructTriples_2 (seq '.' _ConstructTriples_3))
    start_production(:_ConstructTriples_2, as_hash: true)
    production(:_ConstructTriples_2) do |value|
      value[:_ConstructTriples_3]
    end

    # TriplesSameSubject ::= VarOrTerm PropertyListNotEmpty
    #                      | TriplesNode PropertyList | ReifiedTripleBlock
    #
    #   (rule TriplesSameSubject
    #    (alt _TriplesSameSubject_1 _TriplesSameSubject_2 ReifiedTripleBlock))
    #   (rule _TriplesSameSubject_1 (seq VarOrTerm PropertyListNotEmpty))
    #   (rule _TriplesSameSubject_2 (seq TriplesNode PropertyList))
    #
    # Returns patterns
    production(:TriplesSameSubject) do |value|
      pattern = if value[:VarOrTerm]
        value[:PropertyListNotEmpty]
      elsif value[:TriplesNode]
        value[:TriplesNode][:pattern] + Array(value[:PropertyList])
      elsif value[:ReifiedTripleBlock]
        value[:ReifiedTripleBlock]
      else
        []
      end
      pattern
    end

    # (rule _TriplesSameSubject_1 (seq VarOrTerm PropertyListNotEmpty))
    start_production(:_TriplesSameSubject_1, as_hash: true)

    # (rule _TriplesSameSubject_2 (seq TriplesNode PropertyList))
    start_production(:_TriplesSameSubject_2, as_hash: true)

    # PropertyList ::= PropertyListNotEmpty?
    
    # PropertyListNotEmpty ::= Verb ObjectList
    #                          ( ';' ( Verb ObjectList )? )*
    #
    #   (rule PropertyListNotEmpty (seq Verb ObjectList _PropertyListNotEmpty_1))
    #   (rule _PropertyListNotEmpty_1 (star _PropertyListNotEmpty_2))
    #   (rule _PropertyListNotEmpty_2 (seq ';' _PropertyListNotEmpty_3))
    #   (rule _PropertyListNotEmpty_3 (opt _PropertyListNotEmpty_4))
    #   (rule _PropertyListNotEmpty_4 (seq Verb ObjectList))
    #
    # Returns patterns
    start_production(:PropertyListNotEmpty, as_hash: true) do |data|
      # If we're in an  AnnotationPathBlock, use reification information
      if anno_data = prod_data[:AnnotationData]
        # Allocate a reifier ID, if necessary and use as subject
        prod_data[:Subject] = anno_data[:curReifier] ||= bnode
      end

      # If options has a `:_rept_data` entry, use it to get the subject
      subject =  prod_data[:Subject] || prod_data[:TriplesNode] || data[:_rept_data].last[:VarOrTerm]
      error(nil, "Expected VarOrTerm or TriplesNode or GraphNode", production: :PropertyListNotEmpty) if !subject
      data[:Subject] = subject
    end
    production(:PropertyListNotEmpty) do |value|
      patterns = Array(value[:ObjectList][:pattern])
      value[:_PropertyListNotEmpty_1].each do |plne|
        patterns += plne[:pattern]
      end
      patterns
    end

    # (rule _PropertyListNotEmpty_2 (seq ';' _PropertyListNotEmpty_3))
    start_production(:_PropertyListNotEmpty_2, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
    end
    production(:_PropertyListNotEmpty_2) do |value|
      value[:_PropertyListNotEmpty_3]
    end

    # (rule _PropertyListNotEmpty_4 (seq Verb ObjectList))
    start_production(:_PropertyListNotEmpty_4, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
    end
    production(:_PropertyListNotEmpty_4) do |value|
      value[:ObjectList]
    end

    # Verb ::= VarOrIri | 'a'
    #
    # Output to input is `:Verb`.
    start_production(:Verb, as_hash: true, insensitive_strings: false)
    production(:Verb) do |value|
      value == 'a' ? RDF.type.dup.tap {|a| a.lexical = 'a'} : value
    end

    # ObjectList ::= Object ( ',' Object )*
    #
    #   (rule ObjectList (seq Object _ObjectList_1))
    #   (rule _ObjectList_1 (star _ObjectList_2))
    #   (rule _ObjectList_2 (seq ',' Object))
    #
    # Returns objects and patterns
    start_production(:ObjectList, as_hash: true) do |data|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:Subject] = prod_data[:Subject]
      data[:Verb] = data[:_rept_data].last[:Verb]
      error(nil, "Expected Subject", production: :ObjectList) if !data[:Subject]
      error(nil, "Expected Verb", production: :ObjectList) if !(data[:Verb])
    end
    production(:ObjectList) do |value|
      objects = Array(value[:Object][:object])
      patterns = Array(value[:Object][:pattern])

      value[:_ObjectList_1].each do |ob|
        objects << ob[:object]
        patterns += Array(ob[:pattern])
      end

      {
        object: objects,
        pattern: patterns
      }
    end

    # (rule _ObjectList_2 (seq ',' Object))
    start_production(:_ObjectList_2, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
      data[:Verb] = prod_data[:Verb]
    end
    production(:_ObjectList_2) do |value|
      value[:Object]
    end

    # Object ::= GraphNode Annotation
    #
    # Sets `:Subject` and `:Verb` in data from input.
    start_production(:Object, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
      data[:Verb] = prod_data[:Verb]
    end
    production(:Object) do |value, data|
      subject = data[:Subject]
      verb = data[:Verb]
      object = value[:GraphNode][:object]
      patterns = [RDF::Query::Pattern.new(subject, verb, object)]
      {
        object: object,
        pattern: patterns + value[:GraphNode][:pattern] + value[:Annotation]
      }
    end


    # TriplesSameSubjectPath ::= VarOrTerm PropertyListPathNotEmpty
    #                          | TriplesNodePath PropertyListPath
    #                          | ReifiedTripleBlockPath
    #
    #  (rule TriplesSameSubjectPath
    #    (alt _TriplesSameSubjectPath_1 _TriplesSameSubjectPath_2 ReifiedTripleBlockPath))
    #
    # Returns patterns
    production(:TriplesSameSubjectPath) do |value|
      pattern = if value[:VarOrTerm]
        value[:PropertyListPathNotEmpty]
      elsif value[:TriplesNodePath]
        value[:TriplesNodePath][:pattern] + Array(value[:PropertyListPath])
      elsif value[:ReifiedTripleBlockPath]
        value[:ReifiedTripleBlockPath]
      else
        []
      end
      pattern
    end

    #  (rule _TriplesSameSubjectPath_1 (seq VarOrTerm PropertyListPathNotEmpty))
    start_production(:_TriplesSameSubjectPath_1, as_hash: true)

    #  (rule _TriplesSameSubjectPath_2 (seq TriplesNodePath PropertyListPath))
    start_production(:_TriplesSameSubjectPath_2, as_hash: true)

    # PropertyListPathNotEmpty ::= ( VerbPath | VerbSimple ) ObjectListPath
    #                              ( ';' ( ( VerbPath | VerbSimple )
    #                                      ObjectListPath )? )*
    #
    #  (rule PropertyListPathNotEmpty
    #   (seq _PropertyListPathNotEmpty_1 ObjectListPath _PropertyListPathNotEmpty_2))
    #
    # Sets `:Subject` in data from either `:VarOrTerm`,
    # `:TriplesNode`, or `:GraphNode` in input with error checking.
    #
    # Returns patterns
    start_production(:PropertyListPathNotEmpty, as_hash: true) do |data|
      # If we're in an  AnnotationPathBlock, use reification information
      if anno_data = prod_data[:AnnotationData]
        # Allocate a reifier ID, if necessary and use as subject
        prod_data[:Subject] = anno_data[:curReifier] ||= bnode
      end

      # If options has a `:_rept_data` entry, use it to get the subject
      subject = prod_data[:Subject] ||
                prod_data[:TriplesNode] ||
                data[:_rept_data].last[:VarOrTerm]
      error(nil, "Expected Subject, got nothing", production: :PropertyListPathNotEmpty) if !subject
      data[:Subject] = subject
    end
    production(:PropertyListPathNotEmpty) do |value|
      patterns = Array(value[:ObjectListPath][:pattern])
      value[:_PropertyListPathNotEmpty_2].each do |plpne|
        patterns += plpne[:pattern]
      end
      patterns
    end

    # (rule _PropertyListPathNotEmpty_1 (alt VerbPath VerbSimple))

    # (rule _PropertyListPathNotEmpty_2 (star _PropertyListPathNotEmpty_3))
    start_production(:_PropertyListPathNotEmpty_2) do |data|
      data[:Subject] = prod_data[:Subject]
    end
    production(:_PropertyListPathNotEmpty_2) do |value|
      value.flatten
    end

    # (rule _PropertyListPathNotEmpty_3 (seq ';' _PropertyListPathNotEmpty_4))
    start_production(:_PropertyListPathNotEmpty_3, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
    end
    production(:_PropertyListPathNotEmpty_3) do |value|
      value[:_PropertyListPathNotEmpty_4]
    end

    # (rule _PropertyListPathNotEmpty_4 (opt _PropertyListPathNotEmpty_5))
    start_production(:_PropertyListPathNotEmpty_4) do |data|
      data[:Subject] = prod_data[:Subject]
    end

    # (rule _PropertyListPathNotEmpty_5 (seq _PropertyListPathNotEmpty_6 ObjectListPath))
    start_production(:_PropertyListPathNotEmpty_5, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
    end
    production(:_PropertyListPathNotEmpty_5) do |value|
      value[:ObjectListPath]
    end

    # VerbPath ::= Path
    start_production(:VerbPath, as_hash: true)
    production(:VerbPath) do |value|
      value[:Path]
    end

    # VerbSimple ::= Var
    production(:VerbSimple) do |value|
      value.first[:Var]
    end

    # ObjectListPath ::= ObjectPath ("," ObjectPath)*
    #
    # Addes `:Subject` from input to data with error checking.
    # Also adds either `:Verb` or `:VerbPath`
    #
    # Returns objects and patterns
    start_production(:ObjectListPath, as_hash: true) do |data|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:Subject] = prod_data[:Subject]
      data[:Verb] = data[:_rept_data].last[:_PropertyListPathNotEmpty_1] ||
                    data[:_rept_data].last[:_PropertyListPathNotEmpty_6]
      error(nil, "Expected Subject", production: :ObjectListPath) if !data[:Subject]
      error(nil, "Expected Verb", production: :ObjectListPath) if !(data[:Verb])
    end
    production(:ObjectListPath) do |value|
      objects = Array(value[:ObjectPath][:object])
      patterns = Array(value[:ObjectPath][:pattern])
      value[:_ObjectListPath_1].each do |olp|
        objects << olp[:object]
        patterns += olp[:pattern]
      end
      {
        object: objects,
        pattern: patterns
      }
    end

    # (rule _ObjectListPath_1 (star _ObjectListPath_2))
    start_production(:_ObjectListPath_1, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
      data[:Verb] = prod_data[:Verb]
    end

    # (rule _ObjectListPath_2 (seq ',' ObjectPath))
    start_production(:_ObjectListPath_2, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
      data[:Verb] = prod_data[:Verb]
    end
    production(:_ObjectListPath_2) do |value|
      value[:ObjectPath]
    end

    # ObjectPath ::= GraphNodePath AnnotationPath
    #
    # Adds `:Subject` and `:Verb` to data from input.
    #
    # Returns patterns and object
    start_production(:ObjectPath, as_hash: true) do |data|
      data[:Subject] = prod_data[:Subject]
      data[:Verb] = prod_data[:Verb]
    end
      
    production(:ObjectPath) do |value, data|
      subject = data[:Subject]
      verb = data[:Verb]
      object = value[:GraphNodePath][:object]
      patterns = if verb.is_a?(SPARQL::Algebra::Query)
        # It's a path
        [SPARQL::Algebra::Expression(:path, subject, verb, object)]
      else
        [RDF::Query::Pattern.new(subject, verb, object)]
      end
      {
        object: object,
        pattern: patterns + value[:GraphNodePath][:pattern] + value[:AnnotationPath]
      }
    end

    # Path ::= PathAlternative
    #
    # Output an IRI or path.
    production(:Path) do |value|
      value.last[:PathAlternative]
    end

    # PathAlternative ::= PathSequence ( '|' PathSequence )*
    #
    # Input is `:PathSequence` containing one or more path objects.
    # Output is the resulting path, containing a nested sequence of `Algebra::Alt` connecting the elements from `:PathSequence`, unless there is only one such element, in which case it is added directly.
    start_production(:PathAlternative, as_hash: true)
    production(:PathAlternative) do |value|
      lhs = value[:PathSequence]
      while value[:_PathAlternative_1] && !value[:_PathAlternative_1].empty?
        rhs = value[:_PathAlternative_1].shift
        lhs = SPARQL::Algebra::Expression[:alt, lhs, rhs]
      end
      lhs
    end

    #  (rule _PathAlternative_2 (seq '|' PathSequence))
    start_production(:_PathAlternative_2, as_hash: true)
    production(:_PathAlternative_2) do |value|
      value[:PathSequence]
    end

    # PathSequence ::= PathEltOrInverse ( '/' PathEltOrInverse )*
    #
    # Input is `:PathSequence` containing one or more path objects.
    # Output a path containing a nested sequence of `Algebra::Seq` connecting the elements from `:PathSequence`, unless there is only one such element, in which case it is added directly.
    start_production(:PathSequence, as_hash: true)
    production(:PathSequence) do |value|
      lhs = value[:PathEltOrInverse]
      while value[:_PathSequence_1] && !value[:_PathSequence_1].empty?
        rhs = value[:_PathSequence_1].shift
        lhs = SPARQL::Algebra::Expression[:seq, lhs, rhs]
      end
      lhs
    end

    #  (rule _PathSequence_2 (seq '/' PathEltOrInverse))
    start_production(:_PathSequence_2, as_hash: true)
    production(:_PathSequence_2) do |value|
      value[:PathEltOrInverse]
    end

    # PathElt ::= PathPrimary PathMod?
    #
    #   (rule PathElt (seq PathPrimary _PathElt_1))
    #   (rule _PathElt_1 (opt PathMod))
    #
    # Output is a path, a possibly modified `:PathPrimary`.
    start_production(:PathElt, as_hash: true)
    production(:PathElt) do |value|
      if path_mod = value[:_PathElt_1]
        # Add primary path to operand
        op_len = path_mod.operands.length
        path_mod.operands[op_len-1] = value[:PathPrimary]
        path_mod
      else
        value[:PathPrimary]
      end
    end

    # PathEltOrInverse ::= PathElt | '^' PathElt
    #
    # Input is `:Path`, or a reversed path if it is an array.
    # Output is a possibly reversed path.
    production(:PathEltOrInverse) do |value|
      if value.is_a?(Array)
        SPARQL::Algebra::Expression(:reverse, value.last[:PathElt])
      else
        value
      end
    end

    # PathMod ::= '*' | '?' | '+' | '{' INTEGER? (',' INTEGER?)? '}'
    #
    #   (rule PathMod (alt '?' '*' '+' _PathMod_1))
    #   (rule _PathMod_1 (seq '{' _PathMod_2 _PathMod_3 '}'))
    #   (rule _PathMod_2 (opt INTEGER))
    #   (rule _PathMod_3 (opt _PathMod_4))
    #   (rule _PathMod_4 (seq ',' _PathMod_5))
    #   (rule _PathMod_5 (opt INTEGER))
    production(:PathMod) do |value|
      if value.is_a?(SPARQL::Algebra::Expression)
        value
      elsif value
        # Last operand added in :PathElt
        SPARQL::Algebra::Expression("path#{value}", RDF.nil)
      end
    end

    start_production(:_PathMod_1, as_hash: true)
    production(:_PathMod_1) do |value|
      raise Error, "expect property range to have integral elements" if
        value[:_PathMod_2].nil? && value[:_PathMod_3] == :*
      min = value[:_PathMod_2] || 0
      max = value[:_PathMod_3] || min

      # Last operand added in :PathElt
      SPARQL::Algebra::Expression(:pathRange, min, max, RDF.nil)
    end

    #   (rule _PathMod_4 (seq ',' _PathMod_5))
    start_production(:_PathMod_4, as_hash: true)
    production(:_PathMod_4) do |value|
      value[:_PathMod_5] || :*
    end

    # PathPrimary ::= iri | 'a' | '!' PathNegatedPropertySet | '(' Path ')'
    #
    #   (rule PathPrimary (alt iri 'a' _PathPrimary_1 _PathPrimary_2))
    #   (rule _PathPrimary_1 (seq '!' PathNegatedPropertySet))
    #   (rule _PathPrimary_2 (seq '(' Path ')'))
    start_production(:PathPrimary, insensitive_strings: false)
    production(:PathPrimary) do |value|
      if value == 'a'
        RDF.type.dup.tap {|a| a.lexical = 'a'}
      else
        value
      end
    end

    #   (rule _PathPrimary_1 (seq '!' PathNegatedPropertySet))
    production(:_PathPrimary_1) {|value| value.last[:PathNegatedPropertySet]}

    #   (rule _PathPrimary_2 (seq '(' Path ')'))
    production(:_PathPrimary_2) {|value| value[1][:Path]}

    # PathNegatedPropertySet ::= PathOneInPropertySet |
    #                            '('
    #                            ( PathOneInPropertySet
    #                              ( '|' PathOneInPropertySet )*
    #                            )?
    #                           ')'
    #
    #   (rule PathNegatedPropertySet (alt PathOneInPropertySet _PathNegatedPropertySet_1))
    #   (rule _PathNegatedPropertySet_1 (seq '(' _PathNegatedPropertySet_2 ')'))
    #   (rule _PathNegatedPropertySet_2 (opt _PathNegatedPropertySet_3))
    #   (rule _PathNegatedPropertySet_3
    #    (seq PathOneInPropertySet _PathNegatedPropertySet_4))
    #   (rule _PathNegatedPropertySet_4 (star _PathNegatedPropertySet_5))
    #   (rule _PathNegatedPropertySet_5 (seq '|' PathOneInPropertySet))
    #
    production(:PathNegatedPropertySet) do |value|
      SPARQL::Algebra::Expression(:notoneof, *Array(value))
    end

    #   (rule _PathNegatedPropertySet_1 (seq '(' _PathNegatedPropertySet_2 ')'))
    production(:_PathNegatedPropertySet_1) do |value|
      value[1][:_PathNegatedPropertySet_2]
    end

    #   (rule _PathNegatedPropertySet_3
    #    (seq PathOneInPropertySet _PathNegatedPropertySet_4))
    start_production(:_PathNegatedPropertySet_3, as_hash: true)
    production(:_PathNegatedPropertySet_3) do |value|
      value[:_PathNegatedPropertySet_4].unshift(value[:PathOneInPropertySet])
    end

    #   (rule _PathNegatedPropertySet_5 (seq '|' PathOneInPropertySet))
    production(:_PathNegatedPropertySet_5) do |value|
      value.last[:PathOneInPropertySet]
    end

    # PathOneInPropertySet ::= iri | 'a' | '^' ( iri | 'a' )
    #
    #   (rule PathOneInPropertySet (alt iri 'a' _PathOneInPropertySet_1))
    #   (rule _PathOneInPropertySet_1 (seq '^' _PathOneInPropertySet_2))
    #   (rule _PathOneInPropertySet_2 (alt iri 'a'))
    start_production(:PathOneInPropertySet, insensitive_strings: false)
    production(:PathOneInPropertySet) do |value|
      if value == 'a'
        RDF.type.dup.tap {|a| a.lexical = 'a'}
      elsif value.is_a?(RDF::URI)
        value
      else
        SPARQL::Algebra::Expression(:reverse, value.last[:_PathOneInPropertySet_2])
      end
    end

    # BlankNodePropertyList   ::= '[' PropertyListNotEmpty ']'
    start_production(:BlankNodePropertyList, as_hash: true) do |data|
      data[:Subject] = prod_data[:TriplesNode]
    end
    production(:BlankNodePropertyList) do |value, data|
      {
        object: data[:Subject],
        pattern: value[:PropertyListNotEmpty]
      }
    end

    # TriplesNode ::= Collection | BlankNodePropertyList
    #
    # Returns object and patterns
    start_production(:TriplesNode) do |data|
      data[:TriplesNode] = bnode
    end
    production(:TriplesNode) do |value, data|
      # Record the node for downstream productions XXX
      prod_data[:TriplesNode] = data[:TriplesNode]

      value.is_a?(Hash) ? value : {object: data[:TriplesNode], pattern: value}
    end

    # TriplesNodePath ::= CollectionPath | BlankNodePropertyListPath
    #
    # Returns object and patterns
    start_production(:TriplesNodePath) do |data|
      # Called after Verb. The prod_data stack should have Subject and Verb elements
      data[:TriplesNode] = bnode
    end
    production(:TriplesNodePath) do |value, data|
      # Record the node for downstraem productions
      prod_data[:TriplesNode] = data[:TriplesNode]

      value.is_a?(Hash) ? value : {object: data[:TriplesNode], pattern: value}
    end

    # BlankNodePropertyListPath ::= '[' PropertyListPathNotEmpty ']'
    #
    # Returns object and patterns
    start_production(:BlankNodePropertyListPath, as_hash: true) do |data|
      data[:Subject] = prod_data[:TriplesNode]
    end
    production(:BlankNodePropertyListPath) do |value, data|
      {
        object: data[:Subject],
        pattern: value[:PropertyListPathNotEmpty]
      }
    end

    # Collection ::= '(' GraphNode+ ')'
    #
    #   (rule Collection (seq '(' _Collection_1 ')'))
    #   (rule _Collection_1 (plus GraphNode))
    #
    # Returns patterns
    start_production(:Collection, as_hash: true) do |data|
      # Tells the TriplesNode production to collect and not generate statements
      data[:Subject] = prod_data[:TriplesNode]
    end
    production(:Collection) do |value, data|
      expand_collection(data[:Subject], value[:_Collection_1])
    end

    # CollectionPath ::= "(" GraphNodePath+ ")"
    #
    #   (rule CollectionPath (seq '(' _CollectionPath_1 ')'))
    #   (rule _CollectionPath_1 (plus GraphNodePath))
    #
    # Returns patterns
    start_production(:CollectionPath, as_hash: true) do |data|
      # Tells the TriplesNode production to collect and not generate statements
      data[:Subject] = prod_data[:TriplesNode]
    end
    production(:CollectionPath) do |value, data|
      expand_collection(data[:Subject], value[:_CollectionPath_1])
    end

    # AnnotationPath ::= ( Reifier | AnnotationBlockPath )*
    #
    # Returns patterns
    start_production(:AnnotationPath, as_hash: true) do |data|
      object = data[:_rept_data].first[:GraphNodePath][:object]
      error("AnnotationPath", "Expected Subject", production: :AnnotationPath) unless prod_data[:Subject]
      error("AnnotationPath", "Expected Verb", production: :AnnotationPath) unless prod_data[:Verb]
      error("AnnotationPath", "Expected Object", production: :AnnotationPath) unless object
      data[:curReifier] = nil
      data[:TripleTerm] = RDF::Query::Pattern.new(prod_data[:Subject], prod_data[:Verb], object, tripleTerm: true)
    end

    production(:AnnotationPath) do |value|
      value.flatten
    end

    # AnnotationBlockPath ::= '{|' PropertyListPathNotEmpty '|}'
    #
    # Beginning the annotationBlock production, if the curReifier is not set, then the curReifier is assigned a fresh RDF blank node and then yields the RDF triple curReifier rdf:reifies curTripleTerm. The curSubject is taken from the curReifier
    start_production(:AnnotationBlockPath, as_hash: true) do |data|
      # Store AnnotationPath data for reference in PropertyListPathNotEmpty
      data[:AnnotationData] = prod_data
      data[:emit_tt] = prod_data[:curReifier].nil?
    end

    production(:AnnotationBlockPath) do |value, data|
      patterns = if data[:emit_tt]
        reifier = data[:AnnotationData][:curReifier]
        [RDF::Query::Pattern.new(reifier, RDF.reifies, prod_data[:TripleTerm])]
      else
        []
      end
      data[:AnnotationData][:curReifier] = nil
      patterns += value[:PropertyListPathNotEmpty]
      patterns
    end

    # Annotation ::= ( Reifier | AnnotationBlock )*
    #
    # Returns patterns
    start_production(:Annotation) do |data|
      object = data[:_rept_data].first[:GraphNode][:object]
      error("AnnotationPath", "Expected Subject", production: :AnnotationPath) unless prod_data[:Subject]
      error("AnnotationPath", "Expected Verb", production: :AnnotationPath) unless prod_data[:Verb]
      error("AnnotationPath", "Expected Object", production: :AnnotationPath) unless object
      data[:curReifier] = nil
      data[:TripleTerm] = RDF::Query::Pattern.new(prod_data[:Subject], prod_data[:Verb], object, tripleTerm: true)
    end

    production(:Annotation) do |value|
      value.flatten
    end

    # AnnotationBlock ::= '{|' PropertyListPathNotEmpty '|}'
    #
    # Beginning the annotationBlock production, if the curReifier is not set, then the curReifier is assigned a fresh RDF blank node and then yields the RDF triple curReifier rdf:reifies curTripleTerm. The curSubject is taken from the curReifier
    start_production(:AnnotationBlock, as_hash: true) do |data|
      # Store AnnotationPath data for reference in PropertyListPathNotEmpty
      data[:AnnotationData] = prod_data
      data[:emit_tt] = prod_data[:curReifier].nil?
    end

    production(:AnnotationBlock) do |value, data|
      patterns = []
      if data[:emit_tt]
        reifier = data[:AnnotationData][:curReifier]
        patterns = [RDF::Query::Pattern.new(reifier, RDF.reifies, prod_data[:TripleTerm])]
      end
      data[:AnnotationData][:curReifier] = nil
      patterns += value[:PropertyListNotEmpty]
      patterns
    end

    # GraphNode ::= VarOrTerm | TriplesNode
    #
    # Returns object and patterns
    production(:GraphNode) do |value|
      value.is_a?(Hash) ? value : {object: value, pattern: []}
    end

    # GraphNodePath ::= VarOrTerm | TriplesNodePath | ReifiedTriple
    #
    # Returns object and patterns
    production(:GraphNodePath) do |value|
      value.is_a?(Hash) ? value : {object: value, pattern: []}
    end

    # ReifiedTriple ::= '<<' ReifiedTripleSubject Verb ReifiedTripleObject Reifier? '>>'
    #
    #   (rule ReifiedTriple
    #    (seq '<<' ReifiedTripleSubject Verb ReifiedTripleObject _ReifiedTriple_1 '>>'))
    #   (rule _ReifiedTriple_1 (opt Reifier))
    #
    # Returns reifier and pattern. Saves reifier in prod_data
    start_production(:ReifiedTriple, as_hash: true)
    production(:ReifiedTriple) do |value, data|
      subject = value[:ReifiedTripleSubject]
      predicate = value[:Verb]
      object = value[:ReifiedTripleObject]
      reifier = data[:curReifier] || bnode
      prod_data[:Subject] = reifier

      {
        object: reifier,
        pattern: [RDF::Query::Pattern.new(
                   reifier,
                   RDF.reifies,
                   RDF::Query::Pattern.new(subject, predicate, object, tripleTerm: true))]
      }
    end

    # TripleTerm ::= ::= '<<(' TripleTermSubject Verb TripleTermObject ')>>'
    #
    # Input is subject, verb and object.
    # Output is a triple term.
    start_production(:TripleTerm, as_hash: true)
    production(:TripleTerm) do |value|
      RDF::Query::Pattern.new(value[:TripleTermSubject], value[:Verb], value[:TripleTermObject], tripleTerm: true)
    end

    # TripleTermData ::= '<<(' TripleTermDataSubject ( iri | 'a' ) TripleTermDataObject ')>>'
    #
    #   (rule TripleTermData
    #    (seq '<<(' TripleTermDataSubject _TripleTermData_1 TripleTermDataObject ')>>'))
    #   (rule _TripleTermData_1 (alt iri 'a'))
    start_production(:TripleTermData, as_hash: true)
    production(:TripleTermData) do |value|
      RDF::Query::Pattern.new(value[:TripleTermDataSubject], value[:_TripleTermData_1], value[:TripleTermDataObject], tripleTerm: true)
    end

    #   (rule _TripleTermData_1 (alt iri 'a'))
    production(:_TripleTermData_1) do |value|
      if value == 'a'
        RDF.type.dup.tap {|a| a.lexical = 'a'}
      else
        value
      end
    end

    # Expression ::= ConditionalOrExpression
    production(:Expression) do |value|
      value.first[:ConditionalOrExpression]
    end

    # ConditionalOrExpression ::= ConditionalAndExpression
    #                             ( '||' ConditionalAndExpression )*
    #
    #   (rule ConditionalOrExpression
    #    (seq ConditionalAndExpression _ConditionalOrExpression_1))
    #   (rule _ConditionalOrExpression_1 (star _ConditionalOrExpression_2))
    start_production(:ConditionalOrExpression, as_hash: true)
    production(:ConditionalOrExpression) do |value|
      add_operator_expressions(value[:ConditionalAndExpression], *value[:_ConditionalOrExpression_1])
    end

    #   (rule _ConditionalOrExpression_2 (seq '||' ConditionalAndExpression))
    production(:_ConditionalOrExpression_2) do |value|
      [:or, value.last[:ConditionalAndExpression]]
    end

    # ConditionalAndExpression ::= ValueLogical ( '&&' ValueLogical )*
    #
    #   (rule ConditionalAndExpression (seq ValueLogical _ConditionalAndExpression_1))
    #   (rule _ConditionalAndExpression_1 (star _ConditionalAndExpression_2))
    start_production(:ConditionalAndExpression, as_hash: true)
    production(:ConditionalAndExpression) do |value|
      add_operator_expressions(value[:ValueLogical], *value[:_ConditionalAndExpression_1])
    end

    #   (rule _ConditionalAndExpression_2 (seq '&&' ValueLogical))
    production(:_ConditionalAndExpression_2) do |value|
      [:and, value.last[:ValueLogical]]
    end

    # ValueLogical ::= RelationalExpression
    production(:ValueLogical) do |value|
      value.first[:RelationalExpression]
    end

    # RelationalExpression ::= NumericExpression
    #                          ( '=' NumericExpression
    #                          | '!=' NumericExpression
    #                          | '<' NumericExpression
    #                          | '>' NumericExpression
    #                          | '<=' NumericExpression
    #                          | '>=' NumericExpression
    #                          | 'IN' ExpressionList
    #                          | 'NOT' 'IN' ExpressionList
    #                          )?
    #
    #   (rule RelationalExpression (seq NumericExpression _RelationalExpression_1))
    #   (rule _RelationalExpression_1 (opt _RelationalExpression_2))
    #   (rule _RelationalExpression_2
    #    (alt _RelationalExpression_3 _RelationalExpression_4 _RelationalExpression_5
    #     _RelationalExpression_6 _RelationalExpression_7 _RelationalExpression_8
    #     _RelationalExpression_9 _RelationalExpression_10 ))
    #   (rule _RelationalExpression_3 (seq '=' NumericExpression))
    #   (rule _RelationalExpression_4 (seq '!=' NumericExpression))
    #   (rule _RelationalExpression_5 (seq '<' NumericExpression))
    #   (rule _RelationalExpression_6 (seq '>' NumericExpression))
    #   (rule _RelationalExpression_7 (seq '<=' NumericExpression))
    #   (rule _RelationalExpression_8 (seq '>=' NumericExpression))
    #   (rule _RelationalExpression_9 (seq 'IN' ExpressionList))
    #   (rule _RelationalExpression_10 (seq 'NOT' 'IN' ExpressionList))
    #
    start_production(:RelationalExpression, as_hash: true)
    production(:RelationalExpression) do |value|
      if Array(value[:_RelationalExpression_1]).empty?
        value[:NumericExpression]
      else
        comparator, rhs = value[:_RelationalExpression_1]
        SPARQL::Algebra::Expression.for(comparator, value[:NumericExpression], *Array(rhs))
      end
    end

    # (rule _RelationalExpression_2
    #   (alt _RelationalExpression_3 _RelationalExpression_4 _RelationalExpression_5
    #   _RelationalExpression_6 _RelationalExpression_7 _RelationalExpression_8
    #   _RelationalExpression_9 _RelationalExpression_10 ))
    production(:_RelationalExpression_2) do |value|
      if value.last.is_a?(Hash)
        comparator = value.first.values.first
        rhs = value.last.values.first
        [comparator, rhs]
      else
        value
      end
    end

    # (rule _RelationalExpression_9 (seq 'IN' ExpressionList))
    start_production(:_RelationalExpression_9, as_hash: true, insensitve_strings: :upper)
    production(:_RelationalExpression_9) do |value|
      [:in, value[:ExpressionList]]
    end

    # (rule _RelationalExpression_10 (seq 'NOT' 'IN' ExpressionList))
    start_production(:_RelationalExpression_10, as_hash: true, insensitve_strings: :upper)
    production(:_RelationalExpression_10) do |value|
      [:notin, value[:ExpressionList]]
    end

    # NumericExpression::= AdditiveExpression
    production(:NumericExpression) do |value|
      value.first[:AdditiveExpression]
    end

    # AdditiveExpression ::= MultiplicativeExpression
    #                        ( '+' MultiplicativeExpression
    #                        | '-' MultiplicativeExpression
    #                        | ( NumericLiteralPositive
    #                          | NumericLiteralNegative )
    #                          ( ( '*' UnaryExpression )
    #                          | ( '/' UnaryExpression ) )*
    #                        )*
    start_production(:AdditiveExpression, as_hash: true)
    production(:AdditiveExpression) do |value|
      add_operator_expressions(value[:MultiplicativeExpression], *value[:_AdditiveExpression_1])
    end

    # (rule _AdditiveExpression_3 (seq '+' MultiplicativeExpression))
    production(:_AdditiveExpression_3) do |value|
      [:+, value.last[:MultiplicativeExpression]]
    end

    #  (rule _AdditiveExpression_4 (seq '-' MultiplicativeExpression))
    production(:_AdditiveExpression_4) do |value|
      [:-, value.last[:MultiplicativeExpression]]
    end

    #   (rule _AdditiveExpression_5 (seq _AdditiveExpression_6 _AdditiveExpression_7))
    #   (rule _AdditiveExpression_6 (alt NumericLiteralPositive NumericLiteralNegative))
    #   (rule _AdditiveExpression_7 (star _AdditiveExpression_8))
    #   (rule _AdditiveExpression_8 (alt _AdditiveExpression_9 _AdditiveExpression_10))
    start_production(:_AdditiveExpression_5, as_hash: true)
    production(:_AdditiveExpression_5) do |value|
      op = value[:_AdditiveExpression_6] < 0 ? :- : :+
      lhs = value[:_AdditiveExpression_6].abs + 0
      [op, add_operator_expressions(lhs, *value[:_AdditiveExpression_7])]
    end

    #  (rule _AdditiveExpression_9 (seq '*' UnaryExpression))
    production(:_AdditiveExpression_9) do |value|
      [:*, value.last[:UnaryExpression]]
    end

    #  (rule _AdditiveExpression_10 (seq '/' UnaryExpression))
    production(:_AdditiveExpression_10) do |value|
      [:/, value.last[:UnaryExpression]]
    end

    # MultiplicativeExpression ::= UnaryExpression
    #                              ( '*' UnaryExpression
    #                              | '/' UnaryExpression )*
    start_production(:MultiplicativeExpression, as_hash: true)
    production(:MultiplicativeExpression) do |value|
      add_operator_expressions(value[:UnaryExpression], *value[:_MultiplicativeExpression_1])
    end

    # (rule _MultiplicativeExpression_3 (seq '*' UnaryExpression))
    production(:_MultiplicativeExpression_3) do |value|
      [:*, value.last[:UnaryExpression]]
    end

    # (rule _MultiplicativeExpression_4 (seq '/' UnaryExpression))
    production(:_MultiplicativeExpression_4) do |value|
      [:/, value.last[:UnaryExpression]]
    end

    # UnaryExpression ::= '!' PrimaryExpression
    #                   | '+' PrimaryExpression
    #                   | '-' PrimaryExpression
    #                   | PrimaryExpression
    #
    #   (rule UnaryExpression
    #    (alt _UnaryExpression_1 _UnaryExpression_2 _UnaryExpression_3 PrimaryExpression))
    #   (rule _UnaryExpression_1 (seq '!' PrimaryExpression))
    #   (rule _UnaryExpression_2 (seq '+' PrimaryExpression))
    #   (rule _UnaryExpression_3 (seq '-' PrimaryExpression))

    #   (rule _UnaryExpression_1 (seq '!' PrimaryExpression))
    production(:_UnaryExpression_1) do |value|
      SPARQL::Algebra::Expression[:not, value.last[:PrimaryExpression]]
    end

    #   (rule _UnaryExpression_2 (seq '+' PrimaryExpression))
    production(:_UnaryExpression_2) do |value|
      value.last[:PrimaryExpression]
    end

    #   (rule _UnaryExpression_3 (seq '-' PrimaryExpression))
    production(:_UnaryExpression_3) do |value|
      expr = value.last[:PrimaryExpression]
      if expr.is_a?(RDF::Literal::Numeric)
        -expr
      else
        SPARQL::Algebra::Expression[:"-", expr]
      end
    end

    # ExprTripleTerm ::= '<<(' ExprTripleTermSubject Verb ExprTripleTermObject ')>>'
    start_production(:ExprTripleTerm, as_hash: true)
    production(:ExprTripleTerm) do |value|
      subject = value[:ExprTripleTermSubject]
      predicate = value[:Verb]
      object = value[:ExprTripleTermObject]
      RDF::Query::Pattern.new(subject, predicate, object, tripleTerm: true)
    end

    # BrackettedExpression ::= '(' Expression ')'
    production(:BrackettedExpression) do |value|
      value[1][:Expression]
    end

    #   (rule _BuiltInCall_1 (seq 'STR' '(' Expression ')'))
    start_production(:_BuiltInCall_1, as_hash: true)
    production(:_BuiltInCall_1) do |value|
      SPARQL::Algebra::Operator::Str.new(value[:Expression])
    end

    #   (rule _BuiltInCall_2 (seq 'LANG' '(' Expression ')'))
    start_production(:_BuiltInCall_2, as_hash: true)
    production(:_BuiltInCall_2) do |value|
      SPARQL::Algebra::Operator::Lang.new(value[:Expression])
    end

    #   (rule _BuiltInCall_3 (seq 'LANGMATCHES' '(' Expression ',' Expression ')'))
    start_production(:_BuiltInCall_3, as_hash: false)
    production(:_BuiltInCall_3) do |value|
      SPARQL::Algebra::Operator::LangMatches.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_4 (seq 'DATATYPE' '(' Expression ')'))
    start_production(:_BuiltInCall_4, as_hash: true)
    production(:_BuiltInCall_4) do |value|
      SPARQL::Algebra::Operator::Datatype.new(value[:Expression])
    end

    #   (rule _BuiltInCall_5 (seq 'BOUND' '(' Var ')'))
    start_production(:_BuiltInCall_5, as_hash: true)
    production(:_BuiltInCall_5) do |value|
      SPARQL::Algebra::Operator::Bound.new(value[:Var])
    end

    #   (rule _BuiltInCall_6 (seq 'IRI' '(' Expression ')'))
    start_production(:_BuiltInCall_6, as_hash: true)
    production(:_BuiltInCall_6) do |value|
      SPARQL::Algebra::Operator::IRI.new(value[:Expression])
    end

    #   (rule _BuiltInCall_7 (seq 'URI' '(' Expression ')'))
    start_production(:_BuiltInCall_7, as_hash: true)
    production(:_BuiltInCall_7) do |value|
      SPARQL::Algebra::Operator::IRI.new(value[:Expression])
    end

    #   (rule _BuiltInCall_8 (seq 'BNODE' _BuiltInCall_57))
    #   (rule _BuiltInCall_57 (alt _BuiltInCall_58 NIL))
    #   (rule _BuiltInCall_58 (seq '(' Expression ')'))
    start_production(:_BuiltInCall_8, as_hash: true)
    production(:_BuiltInCall_8) do |value|
      if value[:_BuiltInCall_57].is_a?(RDF::Term)
        SPARQL::Algebra::Operator::BNode.new
      else
        SPARQL::Algebra::Operator::BNode.new(value[:_BuiltInCall_57][1][:Expression])
      end
    end

    #   (rule _BuiltInCall_9 (seq 'RAND' NIL))
    start_production(:_BuiltInCall_9, as_hash: true)
    production(:_BuiltInCall_9) do |value|
      SPARQL::Algebra::Operator::Rand.new
    end

    #   (rule _BuiltInCall_10 (seq 'ABS' '(' Expression ')'))
    start_production(:_BuiltInCall_10, as_hash: true)
    production(:_BuiltInCall_10) do |value|
      SPARQL::Algebra::Operator::Abs.new(value[:Expression])
    end

    #   (rule _BuiltInCall_11 (seq 'CEIL' '(' Expression ')'))
    start_production(:_BuiltInCall_11, as_hash: true)
    production(:_BuiltInCall_11) do |value|
      SPARQL::Algebra::Operator::Ceil.new(value[:Expression])
    end

    #   (rule _BuiltInCall_12 (seq 'FLOOR' '(' Expression ')'))
    start_production(:_BuiltInCall_12, as_hash: true)
    production(:_BuiltInCall_12) do |value|
      SPARQL::Algebra::Operator::Floor.new(value[:Expression])
    end

    #   (rule _BuiltInCall_13 (seq 'ROUND' '(' Expression ')'))
    start_production(:_BuiltInCall_13, as_hash: true)
    production(:_BuiltInCall_13) do |value|
      SPARQL::Algebra::Operator::Round.new(value[:Expression])
    end

    #   (rule _BuiltInCall_14 (seq 'CONCAT' ExpressionList))
    start_production(:_BuiltInCall_14, as_hash: true)
    production(:_BuiltInCall_14) do |value|
      SPARQL::Algebra::Operator::Concat.new(*value[:ExpressionList])
    end

    #   (rule _BuiltInCall_15 (seq 'STRLEN' '(' Expression ')'))
    start_production(:_BuiltInCall_15, as_hash: true)
    production(:_BuiltInCall_15) do |value|
      SPARQL::Algebra::Operator::StrLen.new(value[:Expression])
    end

    #   (rule _BuiltInCall_16 (seq 'UCASE' '(' Expression ')'))
    start_production(:_BuiltInCall_16, as_hash: true)
    production(:_BuiltInCall_16) do |value|
      SPARQL::Algebra::Operator::UCase.new(value[:Expression])
    end

    #   (rule _BuiltInCall_17 (seq 'LCASE' '(' Expression ')'))
    start_production(:_BuiltInCall_17, as_hash: true)
    production(:_BuiltInCall_17) do |value|
      SPARQL::Algebra::Operator::LCase.new(value[:Expression])
    end

    #   (rule _BuiltInCall_18 (seq 'ENCODE_FOR_URI' '(' Expression ')'))
    start_production(:_BuiltInCall_18, as_hash: true)
    production(:_BuiltInCall_18) do |value|
      SPARQL::Algebra::Operator::EncodeForURI.new(value[:Expression])
    end

    #   (rule _BuiltInCall_19 (seq 'CONTAINS' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_19) do |value|
      SPARQL::Algebra::Operator::Contains.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_20 (seq 'STRSTARTS' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_20) do |value|
      SPARQL::Algebra::Operator::StrStarts.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_21 (seq 'STRENDS' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_21) do |value|
      SPARQL::Algebra::Operator::StrEnds.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_22 (seq 'STRBEFORE' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_22) do |value|
      SPARQL::Algebra::Operator::StrBefore.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_23 (seq 'STRAFTER' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_23) do |value|
      SPARQL::Algebra::Operator::StrAfter.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_24 (seq 'YEAR' '(' Expression ')'))
    start_production(:_BuiltInCall_24, as_hash: true)
    production(:_BuiltInCall_24) do |value|
      SPARQL::Algebra::Operator::Year.new(value[:Expression])
    end

    #   (rule _BuiltInCall_25 (seq 'MONTH' '(' Expression ')'))
    start_production(:_BuiltInCall_25, as_hash: true)
    production(:_BuiltInCall_25) do |value|
      SPARQL::Algebra::Operator::Month.new(value[:Expression])
    end

    #   (rule _BuiltInCall_26 (seq 'DAY' '(' Expression ')'))
    start_production(:_BuiltInCall_26, as_hash: true)
    production(:_BuiltInCall_26) do |value|
      SPARQL::Algebra::Operator::Day.new(value[:Expression])
    end

    #   (rule _BuiltInCall_27 (seq 'HOURS' '(' Expression ')'))
    start_production(:_BuiltInCall_27, as_hash: true)
    production(:_BuiltInCall_27) do |value|
      SPARQL::Algebra::Operator::Hours.new(value[:Expression])
    end

    #   (rule _BuiltInCall_28 (seq 'MINUTES' '(' Expression ')'))
    start_production(:_BuiltInCall_28, as_hash: true)
    production(:_BuiltInCall_28) do |value|
      SPARQL::Algebra::Operator::Minutes.new(value[:Expression])
    end

    #   (rule _BuiltInCall_29 (seq 'SECONDS' '(' Expression ')'))
    start_production(:_BuiltInCall_29, as_hash: true)
    production(:_BuiltInCall_29) do |value|
      SPARQL::Algebra::Operator::Seconds.new(value[:Expression])
    end

    #   (rule _BuiltInCall_30 (seq 'TIMEZONE' '(' Expression ')'))
    start_production(:_BuiltInCall_30, as_hash: true)
    production(:_BuiltInCall_30) do |value|
      SPARQL::Algebra::Operator::Timezone.new(value[:Expression])
    end

    #   (rule _BuiltInCall_31 (seq 'TZ' '(' Expression ')'))
    start_production(:_BuiltInCall_31, as_hash: true)
    production(:_BuiltInCall_31) do |value|
      SPARQL::Algebra::Operator::TZ.new(value[:Expression])
    end

    #   (rule _BuiltInCall_32 (seq 'NOW' NIL))
    start_production(:_BuiltInCall_32, as_hash: true)
    production(:_BuiltInCall_32) do |value|
      SPARQL::Algebra::Operator::Now.new
    end

    #   (rule _BuiltInCall_33 (seq 'UUID' NIL))
    start_production(:_BuiltInCall_33, as_hash: true)
    production(:_BuiltInCall_33) do |value|
      SPARQL::Algebra::Operator::UUID.new
    end

    #   (rule _BuiltInCall_34 (seq 'STRUUID' NIL))
    start_production(:_BuiltInCall_34, as_hash: true)
    production(:_BuiltInCall_34) do |value|
      SPARQL::Algebra::Operator::StrUUID.new
    end

    #   (rule _BuiltInCall_35 (seq 'MD5' '(' Expression ')'))
    start_production(:_BuiltInCall_35, as_hash: true)
    production(:_BuiltInCall_35) do |value|
      SPARQL::Algebra::Operator::MD5.new(value[:Expression])
    end

    #   (rule _BuiltInCall_36 (seq 'SHA1' '(' Expression ')'))
    start_production(:_BuiltInCall_36, as_hash: true)
    production(:_BuiltInCall_36) do |value|
      SPARQL::Algebra::Operator::SHA1.new(value[:Expression])
    end

    #   (rule _BuiltInCall_37 (seq 'SHA224' '(' Expression ')'))
    start_production(:_BuiltInCall_37, as_hash: true)
    production(:_BuiltInCall_37) do |value|
      SPARQL::Algebra::Operator::SHA224.new(value[:Expression])
    end

    #   (rule _BuiltInCall_38 (seq 'SHA256' '(' Expression ')'))
    start_production(:_BuiltInCall_38, as_hash: true)
    production(:_BuiltInCall_38) do |value|
      SPARQL::Algebra::Operator::SHA256.new(value[:Expression])
    end

    #   (rule _BuiltInCall_39 (seq 'SHA384' '(' Expression ')'))
    start_production(:_BuiltInCall_39, as_hash: true)
    production(:_BuiltInCall_39) do |value|
      SPARQL::Algebra::Operator::SHA384.new(value[:Expression])
    end

    #   (rule _BuiltInCall_40 (seq 'SHA512' '(' Expression ')'))
    start_production(:_BuiltInCall_40, as_hash: true)
    production(:_BuiltInCall_40) do |value|
      SPARQL::Algebra::Operator::SHA512.new(value[:Expression])
    end

    #   (rule _BuiltInCall_41 (seq 'COALESCE' ExpressionList))
    start_production(:_BuiltInCall_41, as_hash: true)
    production(:_BuiltInCall_41) do |value|
      SPARQL::Algebra::Operator::Coalesce.new(*value[:ExpressionList])
    end

    #   (rule _BuiltInCall_42 (seq 'IF' '(' Expression ',' Expression ',' Expression ')'))
    production(:_BuiltInCall_42) do |value|
      SPARQL::Algebra::Operator::If.new(value[2][:Expression], value[4][:Expression], value[6][:Expression])
    end

    #   (rule _BuiltInCall_43 (seq 'STRLANG' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_43) do |value|
      SPARQL::Algebra::Operator::StrLang.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_44 (seq 'STRDT' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_44) do |value|
      SPARQL::Algebra::Operator::StrDT.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_45 (seq 'sameTerm' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_45) do |value|
      SPARQL::Algebra::Operator::SameTerm.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_46 (seq 'isIRI' '(' Expression ')'))
    start_production(:_BuiltInCall_46, as_hash: true)
    production(:_BuiltInCall_46) do |value|
      SPARQL::Algebra::Operator::IsIRI.new(value[:Expression])
    end

    #   (rule _BuiltInCall_47 (seq 'isURI' '(' Expression ')'))
    start_production(:_BuiltInCall_47, as_hash: true)
    production(:_BuiltInCall_47) do |value|
      SPARQL::Algebra::Operator::IsURI.new(value[:Expression])
    end

    #   (rule _BuiltInCall_48 (seq 'isBLANK' '(' Expression ')'))
    start_production(:_BuiltInCall_48, as_hash: true)
    production(:_BuiltInCall_48) do |value|
      SPARQL::Algebra::Operator::IsBlank.new(value[:Expression])
    end

    #   (rule _BuiltInCall_49 (seq 'isLITERAL' '(' Expression ')'))
    start_production(:_BuiltInCall_49, as_hash: true)
    production(:_BuiltInCall_49) do |value|
      SPARQL::Algebra::Operator::IsLiteral.new(value[:Expression])
    end

    #   (rule _BuiltInCall_50 (seq 'isNUMERIC' '(' Expression ')'))
    start_production(:_BuiltInCall_50, as_hash: true)
    production(:_BuiltInCall_50) do |value|
      SPARQL::Algebra::Operator::IsNumeric.new(value[:Expression])
    end

    #   (rule _BuiltInCall_51 (seq 'ADJUST' '(' Expression ',' Expression ')'))
    production(:_BuiltInCall_51) do |value|
      SPARQL::Algebra::Operator::Adjust.new(value[2][:Expression], value[4][:Expression])
    end

    #   (rule _BuiltInCall_52 (seq 'isTRIPLE' '(' Expression ')'))
    start_production(:_BuiltInCall_52, as_hash: true)
    production(:_BuiltInCall_52) do |value|
      SPARQL::Algebra::Operator::IsTriple.new(value[:Expression])
    end

    #   (rule _BuiltInCall_53
    #    (seq 'TRIPLE' '(' Expression ',' Expression ',' Expression ')'))
    production(:_BuiltInCall_53) do |value|
      SPARQL::Algebra::Operator::Triple.new(value[2][:Expression], value[4][:Expression], value[6][:Expression])
    end

    #   (rule _BuiltInCall_54 (seq 'SUBJECT' '(' Expression ')'))
    start_production(:_BuiltInCall_54, as_hash: true)
    production(:_BuiltInCall_54) do |value|
      SPARQL::Algebra::Operator::Subject.new(value[:Expression])
    end

    #   (rule _BuiltInCall_55 (seq 'PREDICATE' '(' Expression ')'))
    start_production(:_BuiltInCall_55, as_hash: true)
    production(:_BuiltInCall_55) do |value|
      SPARQL::Algebra::Operator::Predicate.new(value[:Expression])
    end

    #   (rule _BuiltInCall_56 (seq 'OBJECT' '(' Expression ')'))
    start_production(:_BuiltInCall_56, as_hash: true)
    production(:_BuiltInCall_56) do |value|
      SPARQL::Algebra::Operator::Object.new(value[:Expression])
    end


    # RegexExpression ::= 'REGEX' '(' Expression ',' Expression
    #                     ( ',' Expression )? ')'
    production(:RegexExpression) do |value|
      expr_list = [value[2][:Expression], value[4][:Expression]]
      if value[5][:_RegexExpression_1]
        expr_list << value[5][:_RegexExpression_1].last[:Expression]
      end
      SPARQL::Algebra::Operator::Regex.new(*expr_list)
    end

    # SubstringExpression ::= 'SUBSTR'
    #                         '(' Expression ',' Expression
    #                         ( ',' Expression )? ')'
    production(:SubstringExpression) do |value|
      expr_list = [value[2][:Expression], value[4][:Expression]]
      if value[5][:_SubstringExpression_1]
        expr_list << value[5][:_SubstringExpression_1].last[:Expression]
      end
      SPARQL::Algebra::Operator::SubStr.new(*expr_list)
    end

    # StrReplaceExpression ::= 'REPLACE'
    #                          '(' Expression ','
    #                          Expression ',' Expression
    #                          ( ',' Expression )? ')'
    production(:StrReplaceExpression) do |value|
      expr_list = [value[2][:Expression], value[4][:Expression], value[6][:Expression]]
      if value[7][:_StrReplaceExpression_1]
        expr_list << value[7][:_StrReplaceExpression_1].last[:Expression]
      end
      SPARQL::Algebra::Operator::Replace.new(*expr_list)
    end

    # ExistsFunc ::= 'EXISTS' GroupGraphPattern
    start_production(:ExistsFunc, as_hash: true)
    production(:ExistsFunc) do |value|
      SPARQL::Algebra::Operator::Exists.new(value&.dig(:GroupGraphPattern, :query))
    end

    # NotExistsFunc ::= 'NOT' 'EXISTS' GroupGraphPattern
    start_production(:NotExistsFunc, as_hash: true)
    production(:NotExistsFunc) do |value|
      SPARQL::Algebra::Operator::NotExists.new(value&.dig(:GroupGraphPattern, :query))
    end

    # Aggregate ::= 'COUNT' '(' 'DISTINCT'? ( '*' | Expression ) ')'
    #             | 'SUM' '(' 'DISTINCT'? Expression ')'
    #             | 'MIN' '(' 'DISTINCT'? Expression ')'
    #             | 'MAX' '(' 'DISTINCT'? Expression ')'
    #             | 'AVG' '(' 'DISTINCT'? Expression ')'
    #             | 'SAMPLE' '(' 'DISTINCT'? Expression ')'
    #             | 'GROUP_CONCAT' '(' 'DISTINCT'? Expression
    #               ( ';' 'SEPARATOR' '=' String )? ')'
    production(:Aggregate) do |value|
      SPARQL::Algebra::Expression.for(*value)
    end

    # (rule _Aggregate_1 (seq 'COUNT' '(' _Aggregate_8 _Aggregate_9 ')'))
    start_production(:_Aggregate_1, as_hash: true, insensitive_strings: :upper)
    production(:_Aggregate_1) do |value|
      expr = value[:_Aggregate_9] unless value[:_Aggregate_9] == '*'
      [:count, (value[:_Aggregate_8] ? :distinct : nil), expr].compact
    end

    # (rule _Aggregate_2 (seq 'SUM' '(' _Aggregate_10 Expression ')'))
    start_production(:_Aggregate_2, as_hash: true, insensitive_strings: :upper)
    production(:_Aggregate_2) do |value|
      [:sum, (value[:_Aggregate_10] ? :distinct : nil), value[:Expression]].compact
    end

    # (rule _Aggregate_3 (seq 'MIN' '(' _Aggregate_11 Expression ')'))
    start_production(:_Aggregate_3, as_hash: true, insensitive_strings: :upper)
    production(:_Aggregate_3) do |value|
      [:min, (value[:_Aggregate_11] ? :distinct : nil), value[:Expression]].compact
    end

    # (rule _Aggregate_4 (seq 'MAX' '(' _Aggregate_12 Expression ')'))
    start_production(:_Aggregate_4, as_hash: true, insensitive_strings: :upper)
    production(:_Aggregate_4) do |value|
      [:max, (value[:_Aggregate_12] ? :distinct : nil), value[:Expression]].compact
    end

    # (rule _Aggregate_5 (seq 'AVG' '(' _Aggregate_13 Expression ')'))
    start_production(:_Aggregate_5, as_hash: true, insensitive_strings: :upper)
    production(:_Aggregate_5) do |value|
      [:avg, (value[:_Aggregate_13] ? :distinct : nil), value[:Expression]].compact
    end

    # (rule _Aggregate_6 (seq 'SAMPLE' '(' _Aggregate_14 Expression ')'))
    start_production(:_Aggregate_6, as_hash: true, insensitive_strings: :upper)
    production(:_Aggregate_6) do |value|
      [:sample, (value[:_Aggregate_14] ? :distinct : nil), value[:Expression]].compact
    end

    # (rule _Aggregate_7
    #   (seq 'GROUP_CONCAT' '(' _Aggregate_15 Expression _Aggregate_16 ')'))
    start_production(:_Aggregate_7, as_hash: true, insensitive_strings: :upper)
    production(:_Aggregate_7) do |value|
      separator = value&.dig(:_Aggregate_16, :String)
      [:group_concat,
        (value[:_Aggregate_15] ? :distinct : nil),
        ([:separator, separator] if separator),
        value[:Expression]
      ].compact
    end

    # (rule _Aggregate_17 (seq ';' 'SEPARATOR' '=' String))
    start_production(:_Aggregate_17, as_hash: true, insensitive_strings: :upper)

    # iriOrFunction ::= iri ArgList?
    #
    #   (rule iriOrFunction (seq iri _iriOrFunction_1))
    #   (rule _iriOrFunction_1 (opt ArgList))
    start_production(:iriOrFunction, as_hash: true)
    production(:iriOrFunction) do |value|
      if value[:_iriOrFunction_1]
        SPARQL::Algebra::Operator::FunctionCall.new(value[:iri], *value[:_iriOrFunction_1])
      else
        value[:iri]
      end
    end

    # RDFLiteral ::= String ( LANG_DIR | '^^' iri )?
    start_production(:RDFLiteral, as_hash: true)
    production(:RDFLiteral) do |value|
      str = value[:String]
      dt = value[:_RDFLiteral_1] if value[:_RDFLiteral_1].is_a?(RDF::URI)
      lang = value[:_RDFLiteral_1] if value[:_RDFLiteral_1].is_a?(String)
      RDF::Literal.new(str, datatype: dt, language: lang)
    end

    # (rule _RDFLiteral_3 (seq '^^' iri))
    production(:_RDFLiteral_3) do |value|
      value.last[:iri]
    end

    # BooleanLiteral ::= 'true' | 'false'
    start_production(:BooleanLiteral, insensitive_strings: false)
    production(:BooleanLiteral) do |value|
      RDF::Literal::Boolean.new(value.downcase)
    end

    # PrefixedName::= PNAME_LN | PNAME_NS
    production(:PrefixedName) do |value|
      # PNAME_NS is just the symbol, PNAME_LN is a resolved IRI
      value.is_a?(Symbol) ? self.prefix(value) : value
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
      when IO, StringIO then EBNF::Unescape.unescape_codepoints(input.read)
      else EBNF::Unescape.unescape_codepoints(input.to_s)
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

    alias_method :peg_parse, :parse

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
    def parse(prod = :QueryUnit)
      res = peg_parse(@input,
        start: prod.to_sym,
        rules: SPARQL::Grammar::Meta::RULES,
        whitespace: WS,
        insensitive_strings: :upper,
        **@options
      )

      # The last thing on the @prod_data stack is the result
      @result = case
      when !res.is_a?(Hash)
        res
      when res.empty?
        nil
      when res[:query]
        res[:query]
      when res[:update]
        res[:update]
      else
        key = res.keys.first
        value = res[key]
        value = [value] unless value.is_a?(Array)
        value.unshift(key)
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
    # @return [Array] list of patterns
    def expand_collection(first, values)
      # Add any triples generated from deeper productions
      patterns = values.map {|v| v[:pattern]}.flatten.compact

      # Create list items for each element in data[:GraphNode]
      list = values.map {|v| v[:object]}.compact
      last = list.pop

      list.each do |r|
        patterns << add_pattern(:Collection, subject: first, predicate: RDF["first"], object: r)
        rest = bnode()
        patterns << add_pattern(:Collection, subject: first, predicate: RDF["rest"], object: rest)
        first = rest
      end

      if last
        patterns << add_pattern(:Collection, subject: first, predicate: RDF["first"], object: last)
      end
      patterns << add_pattern(:Collection, subject: first, predicate: RDF["rest"], object: RDF["nil"])
      patterns
    end

    # add a pattern
    #
    # @param [String] production Production generating pattern
    # @param [Boolean] tripleTerm For Triple Term
    # @param [Hash{Symbol => Object}] options
    def add_pattern(production, tripleTerm: false, **options)
      progress(production, "[:pattern, #{options[:subject]}, #{options[:predicate]}, #{options[:object]}]")
      triple = {}
      triple[:tripleTerm] = true if tripleTerm
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
      RDF::Query::Pattern.new(triple)
    end

    ##
    # Merge query modifiers, datasets, and projections
    #
    # This includes tranforming aggregates if also used with a GROUP BY
    #
    # @see http://www.w3.org/TR/sparql11-query/#convertGroupAggSelectExpressions
    def merge_modifiers(data)
      debug("merge modifiers") {data.inspect}
      query = data[:query] || SPARQL::Algebra::Operator::BGP.new

      vars = Array(data[:Var])
      order = Array(data[:order])
      extensions = data[:extend] || []
      having = data[:having] || []
      values = data[:values] || []

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
        data[:group] = []
      end

      # Add datasets and modifiers in order
      if data[:group]
        group_vars = data[:group]

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

      query = SPARQL::Algebra::Expression[:join, query, values] unless values.empty?

      query = SPARQL::Algebra::Expression[:extend, extensions, query] unless extensions.empty?

      query = SPARQL::Algebra::Expression[:filter, *having, query] unless having.empty?

      query = SPARQL::Algebra::Expression[:order, data[:order], query] unless order.empty?

      # If SELECT * was used, emit a projection with empty variables, vs no projection at all. Only if :all_vars is true
      query = if vars == %w(*)
        options[:all_vars] ? SPARQL::Algebra::Expression[:project, [], query] : query
      elsif !vars.empty?
        SPARQL::Algebra::Expression[:project, vars, query]
      else
        query
      end

      query = SPARQL::Algebra::Expression[data[:DISTINCT_REDUCED], query] if data[:DISTINCT_REDUCED]

      query = SPARQL::Algebra::Expression[:slice, data[:slice][0], data[:slice][1], query] if data[:slice]

      query = SPARQL::Algebra::Expression[:dataset, data[:dataset], query] if data[:dataset] && !data[:dataset].empty?

      query
    end

    # Add joined expressions in for prod1 (op prod2)* to form (op (op 1 2) 3)
    def add_operator_expressions(lhs, *exprs)
      # Iterate through expression to create binary operations
      exprs.each do |op, rhs|
        lhs = SPARQL::Algebra::Expression.for(op, lhs, rhs)
      end
      lhs
    end
  end # class Parser
end # module SPARQL::Grammar
