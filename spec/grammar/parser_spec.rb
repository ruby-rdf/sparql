$:.unshift ".."
require 'spec_helper'

module ProductionRequirements
  def with_production(production, &block)
    block.call(production)
  end

  def it_rejects_empty_input_using(production)
    it "rejects empty input" do
      parser(production).call(%q()).should be_false
    end
  end

  def it_does_not_generate_using(production, input)
    it "Does not generate" do
      parser(production).call(input).should be_false
    end
  end

  def given_it_generates(production, input, result, options = {})
    it "given #{input.inspect} it generates #{present_results(result, options)}" do
      if options[:last]
        # Only look at end of production
        parser(production, options).call(input).last.should == result
      elsif options[:shift]
        parser(production, options).call(input)[1..-1].should == result
      elsif result.is_a?(String)
        sse = SPARQL::Algebra.parse(result)
        parser(production, options).call(input).should == sse
      elsif result.is_a?(Symbol)
        parser(production, options).call(input).to_sxp.should == result.to_s
      else
        parser(production, options).call(input).should == result
      end
    end
  end

  # [28] FunctionCall
  def it_recognizes_function_using(production)
    it "recognizes the FunctionCall nonterminal" do
      it_recognizes_function(production)
    end
  end

  # [41]    GraphNode
  def it_recognizes_graph_node_using(production)
    it "recognizes the GraphNode nonterminal" do
      it_recognizes_graph_node(production)
    end
  end

  # [42]    VarOrTerm
  def it_recognizes_var_or_term_using(production)
    it "recognizes the VarOrTerm nonterminal" do
      it_recognizes_var_or_iriref(production)
    end
  end

  # [43]    VarOrIRIref
  def it_recognizes_var_or_iriref_using(production)
    it "recognizes the VarOrIRIref nonterminal" do
      it_recognizes_var_or_iriref(production)
    end
  end

  # [44] Var
  def it_recognizes_var_using(production)
    it "recognizes the Var nonterminal" do
      it_recognizes_var(production)
    end
  end

  # [45] GraphTerm
  def it_recognizes_graph_term_using(production)
    it "recognizes the GraphTerm nonterminal" do
      it_recognizes_graph_term(production)
    end
  end

  # [46]    Expression
  def it_recognizes_expression_using(production)
    it "recognizes Expression nonterminal" do
      it_recognizes_expression(production)
    end
  end

  # [47]    ConditionalOrExpression
  def it_recognizes_conditional_or_expression_using(production)
    it "recognizes ConditionalOrExpression nonterminal" do
      it_recognizes_conditional_or_expression(production)
    end
  end

  # [48]    ConditionalAndExpression
  def it_recognizes_conditional_and_expression_using(production)
    it "recognizes ConditionalAndExpression nonterminal" do
      it_recognizes_conditional_and_expression(production)
    end
  end

  # [49]    ValueLogical
  def it_recognizes_value_logical_using(production)
    it "recognizes ValueLogical nonterminal" do
      it_recognizes_value_logical(production)
    end
  end

  # [50]    RelationalExpression
  def it_recognizes_relational_expression_using(production)
    it "recognizes RelationalExpression nonterminal" do
      it_recognizes_relational_expression(production)
    end
  end

  # [51]    NumericExpression
  def it_recognizes_numeric_expression_using(production)
    it "recognizes NumericExpression nonterminal" do
      it_recognizes_numeric_expression(production)
    end
  end

  # [52]    AdditiveExpression
  def it_recognizes_additive_expression_using(production)
    it "recognizes AdditiveExpression nonterminal" do
      it_recognizes_additive_expression(production)
    end
  end

  # [53]    MultiplicativeExpression
  def it_recognizes_multiplicative_expression_using(production)
    it "recognizes MultiplicativeExpression nonterminal" do
      it_recognizes_multiplicative_expression(production)
    end
  end

  # [54] UnaryExpression
  def it_recognizes_unary_expression_using(production)
    it "recognizes UnaryExpression nonterminal" do
      it_recognizes_unary_expression(production)
    end
  end

  # [55]    PrimaryExpression
  def it_recognizes_primary_expression_using(production)
    it "recognizes PrimaryExpression nonterminal" do
      it_recognizes_primary_expression(production)
    end
  end

  # [56]    BrackettedExpression ::=       '(' Expression ')'
  def it_recognizes_bracketted_expression_using(production)
    it "recognizes BrackettedExpression nonterminal" do
      it_recognizes_bracketted_expression(production)
    end
  end

  # [57]    BuiltInCall
  def it_recognizes_built_in_call_using(production)
    it "recognizes BuiltInCall nonterminal" do
      it_recognizes_built_in_call(production)
    end
  end

  # [58]    RegexExpression
  def it_recognizes_regex_expression_using(production)
    it "recognizes RegexExpression nonterminal" do
      it_recognizes_regex_expression(production)
    end
  end

  # [59]    IRIrefOrFunction
  def it_recognizes_iriref_or_function_using(production)
    it "recognizes the IRIrefOrFunction nonterminal" do
      it_recognizes_iriref_or_function(production)
    end
  end

  # [60] RDFLiteral
  def it_recognizes_rdf_literal_using(production)
    it "recognizes the RDFLiteral nonterminal" do
      it_recognizes_rdf_literal_without_language_or_datatype(production)
      it_recognizes_rdf_literal_with_language(production)
      it_recognizes_rdf_literal_with_datatype(production)
    end
  end

  # [61] NumericLiteral
  def it_recognizes_numeric_literal_using(production)
    it "recognizes the NumericLiteral nonterminal" do
      it_recognizes_numeric_literal(production)
    end
  end

  # [65] BooleanLiteral
  def it_recognizes_boolean_literal_using(production)
    it "recognizes the BooleanLiteral nonterminal" do
      it_recognizes_boolean_literal(production)
    end
  end

  # [67] IRIref
  def it_recognizes_iriref_using(production)
    it "recognizes the IRIref nonterminal" do
      it_recognizes_iriref(production)
    end
  end

  # [69] BlankNode
  def it_recognizes_blank_node_using(production)
    it "recognizes the BlankNode nonterminal" do
      it_recognizes_blank_node(production)
    end
  end

  # [92] NIL
  def it_recognizes_nil_using(production)
    it "recognizes the NIL terminal" do
      it_recognizes_nil(production)
    end
  end

  def present_results(array, options = {})
    return array if array.is_a?(String)
    return array.to_sxp
  end
end

module ProductionExamples
  # [28] FunctionCall
  def it_recognizes_function(production)
    parser(production).call(%q(<foo>("bar"))).last.should == [RDF::URI("foo"), RDF::Literal("bar")]
    parser(production).call(%q(<foo>())).last.should == [RDF::URI("foo"), RDF["nil"]]
  end

  # [41]    GraphNode                 ::=       VarOrTerm | TriplesNode
  def it_recognizes_graph_node(production)
    it_recognizes_var_or_term(production)
  end

  # [42]    VarOrTerm                 ::=       Var | GraphTerm
  def it_recognizes_var_or_term(production)
    it_recognizes_var(production)
    it_recognizes_graph_term(production)
  end

  # [43]    VarOrIRIref               ::=       Var | IRIref
  def it_recognizes_var_or_iriref(production)
    it_recognizes_var(production)
    it_recognizes_iriref(production)
  end

  # [44]    Var                       ::=       VAR1 | VAR2
  def it_recognizes_var(production)
    it_recognizes_var1(production)
    it_recognizes_var2(production)
  end

  # [45] GraphTerm ::=       IRIref | RDFLiteral | NumericLiteral | BooleanLiteral | BlankNode | NIL
  def it_recognizes_graph_term(production)
    it_recognizes_iriref(production)
    it_recognizes_rdf_literal_without_language_or_datatype(production)
    it_recognizes_rdf_literal_with_language(production)
    it_recognizes_rdf_literal_with_datatype(production)
    it_recognizes_numeric_literal production
    it_recognizes_boolean_literal production
    it_recognizes_blank_node production
    it_recognizes_nil production
  end

  # [46]    Expression ::=       ConditionalOrExpression
  def it_recognizes_expression(production)
    it_recognizes_conditional_or_expression(production)
  end

  # [47]    ConditionalOrExpression ::=       ConditionalAndExpression ( '||' ConditionalAndExpression )*
  def it_recognizes_conditional_or_expression(production)
    parser(production).call(%q(1 || 2)).last.should == SPARQL::Algebra::Expression[:"||", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 || 2 && 3)).last.should == SPARQL::Algebra::Expression[:"||", RDF::Literal(1), [:"&&", RDF::Literal(2), RDF::Literal(3)]]
    parser(production).call(%q(1 && 2 || 3)).last.should == SPARQL::Algebra::Expression[:"||", [:"&&", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)]

    parser(production).call(%q(1 || 2 || 3)).last.should == SPARQL::Algebra::Expression[:"||", [:"||", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)]
    it_recognizes_conditional_and_expression(production)
  end

  # [48]    ConditionalAndExpression ::=       ValueLogical ( '&&' ValueLogical )*
  def it_recognizes_conditional_and_expression(production)
    parser(production).call(%q(1 && 2)).last.should == SPARQL::Algebra::Expression[:"&&", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 && 2 = 3)).last.should == SPARQL::Algebra::Expression[:"&&", RDF::Literal(1), [:"=", RDF::Literal(2), RDF::Literal(3)]]

    parser(production).call(%q(1 && 2 && 3)).last.should == SPARQL::Algebra::Expression[:"&&", [:"&&", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)]
    it_recognizes_value_logical(production)
  end

  # [49]    ValueLogical ::=       RelationalExpression
  def it_recognizes_value_logical(production)
    it_recognizes_relational_expression(production)
  end

  # [50]    RelationalExpression ::= NumericExpression (
  #                                      '=' NumericExpression
  #                                    | '!=' NumericExpression
  #                                    | '<' NumericExpression
  #                                    | '>' NumericExpression
  #                                    | '<=' NumericExpression
  #                                    | '>=' NumericExpression )?
  def it_recognizes_relational_expression(production)
    parser(production).call(%q(1 = 2)).last.should == SPARQL::Algebra::Expression[:"=", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 != 2)).last.should == SPARQL::Algebra::Expression[:"!=", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 < 2)).last.should == SPARQL::Algebra::Expression[:"<", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 > 2)).last.should == SPARQL::Algebra::Expression[:">", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 <= 2)).last.should == SPARQL::Algebra::Expression[:"<=", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 >= 2)).last.should == SPARQL::Algebra::Expression[:">=", RDF::Literal(1), RDF::Literal(2)]

    parser(production).call(%q(1 + 2 = 3)).last.should == SPARQL::Algebra::Expression[:"=", [:"+", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)]
    
    it_recognizes_numeric_expression(production)
  end

  # [51]    NumericExpression ::=       AdditiveExpression
  def it_recognizes_numeric_expression(production)
    it_recognizes_additive_expression(production)
  end

  # [52]    AdditiveExpression ::= MultiplicativeExpression ( '+' MultiplicativeExpression | '-' MultiplicativeExpression )*
  def it_recognizes_additive_expression(production)
    parser(production).call(%q(1 + 2)).last.should == SPARQL::Algebra::Expression[:"+", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 - 2)).last.should == SPARQL::Algebra::Expression[:"-", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(3+4)).last.should == SPARQL::Algebra::Expression[:"+", RDF::Literal(3), RDF::Literal(4)]

    parser(production).call(%q("1" + "2" - "3")).last.should == SPARQL::Algebra::Expression[:"-", [:"+", RDF::Literal("1"), RDF::Literal("2")], RDF::Literal("3")]
    parser(production).call(%q("1" - "2" + "3")).last.should == SPARQL::Algebra::Expression[:"+", [:"-", RDF::Literal("1"), RDF::Literal("2")], RDF::Literal("3")]
    
    it_recognizes_multiplicative_expression(production)
  end

  # [53]    MultiplicativeExpression ::=       UnaryExpression ( '*' UnaryExpression | '/' UnaryExpression )*
  def it_recognizes_multiplicative_expression(production)
    parser(production).call(%q(1 * 2)).last.should == SPARQL::Algebra::Expression[:"*", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(1 / 2)).last.should == SPARQL::Algebra::Expression[:"/", RDF::Literal(1), RDF::Literal(2)]
    parser(production).call(%q(3*4)).last.should == SPARQL::Algebra::Expression[:"*", RDF::Literal(3), RDF::Literal(4)]

    parser(production).call(%q("1" * "2" * "3")).last.should == SPARQL::Algebra::Expression[:"*", [:"*", RDF::Literal("1"), RDF::Literal("2")], RDF::Literal("3")]
    parser(production).call(%q("1" * "2" / "3")).last.should == SPARQL::Algebra::Expression[:"/", [:"*", RDF::Literal("1"), RDF::Literal("2")], RDF::Literal("3")]

    it_recognizes_unary_expression(production)
  end

  # [54] UnaryExpression ::=  '!' PrimaryExpression | '+' PrimaryExpression | '-' PrimaryExpression | PrimaryExpression
  def it_recognizes_unary_expression(production)
    parser(production).call(%q(! "foo")).last.should == SPARQL::Algebra::Expression[:not, RDF::Literal("foo")]
    parser(production).call(%q(+ 1)).last.should == RDF::Literal(1)
    parser(production).call(%q(- 1)).last.should == -RDF::Literal(1)
    parser(production).call(%q(+ "foo")).last.should == RDF::Literal("foo")
    parser(production).call(%q(- "foo")).last.should == SPARQL::Algebra::Expression[:minus, RDF::Literal("foo")]

    it_recognizes_bracketted_expression production
    it_recognizes_built_in_call production
    it_recognizes_iriref_or_function production
    it_recognizes_rdf_literal_without_language_or_datatype(production)
    it_recognizes_rdf_literal_with_language(production)
    it_recognizes_rdf_literal_with_datatype(production)
    #it_recognizes_numeric_literal production             # This conflicts
    it_recognizes_boolean_literal production
    it_recognizes_var production
  end

  # [55]    PrimaryExpression ::=       BrackettedExpression | BuiltInCall | IRIrefOrFunction | RDFLiteral | NumericLiteral | BooleanLiteral | Var
  def it_recognizes_primary_expression(production)
    it_recognizes_bracketted_expression production
    it_recognizes_built_in_call production
    it_recognizes_iriref_or_function production
    it_recognizes_rdf_literal_without_language_or_datatype(production)
    it_recognizes_rdf_literal_with_language(production)
    it_recognizes_rdf_literal_with_datatype(production)
    it_recognizes_numeric_literal production
    it_recognizes_boolean_literal production
    it_recognizes_var production
  end

  # [56]    BrackettedExpression ::=       '(' Expression ')'
  def it_recognizes_bracketted_expression(production)
    parser(production).call(%q(("foo")))[1..-1].should == [RDF::Literal("foo")]
  end

  # [57]    BuiltInCall ::=  'STR' '(' Expression ')'
  #                        | 'LANG' '(' Expression ')'
  #                        | 'LANGMATCHES' '(' Expression ',' Expression ')'
  #                        | 'DATATYPE' '(' Expression ')'
  #                        | 'BOUND' '(' Var ')'
  #                        | 'sameTerm' '(' Expression ',' Expression ')'
  #                        | 'isIRI' '(' Expression ')'
  #                        | 'isURI' '(' Expression ')'
  #                        | 'isBLANK' '(' Expression ')'
  #                        | 'isLITERAL' '(' Expression ')'
  #                        | RegexExpression
  def it_recognizes_built_in_call(production)
    parser(production).call(%q(STR ("foo"))).last.should == SPARQL::Algebra::Expression[:str, RDF::Literal("foo")]
    parser(production).call(%q(LANG ("foo"))).last.should == SPARQL::Algebra::Expression[:lang, RDF::Literal("foo")]
    parser(production).call(%q(LANGMATCHES ("foo", "bar"))).last.should == SPARQL::Algebra::Expression[:langMatches, RDF::Literal("foo"), RDF::Literal("bar")]
    parser(production).call(%q(DATATYPE ("foo"))).last.should == SPARQL::Algebra::Expression[:datatype, RDF::Literal("foo")]
    parser(production).call(%q(sameTerm ("foo", "bar"))).last.should == SPARQL::Algebra::Expression[:sameTerm, RDF::Literal("foo"), RDF::Literal("bar")]
    parser(production).call(%q(isIRI ("foo"))).last.should == SPARQL::Algebra::Expression[:isIRI, RDF::Literal("foo")]
    parser(production).call(%q(isURI ("foo"))).last.should == SPARQL::Algebra::Expression[:isURI, RDF::Literal("foo")]
    parser(production).call(%q(isBLANK ("foo"))).last.should == SPARQL::Algebra::Expression[:isBLANK, RDF::Literal("foo")]
    parser(production).call(%q(isLITERAL ("foo"))).last.should == SPARQL::Algebra::Expression[:isLITERAL, RDF::Literal("foo")]
    parser(production).call(%q(BOUND (?foo))).last.should == SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("foo")]
    parser(production).call(%q(REGEX ("foo", "bar"))).last.should == SPARQL::Algebra::Expression[:regex, RDF::Literal("foo"), RDF::Literal("bar")]
  end

  # [58]    RegexExpression ::=       'REGEX' '(' Expression ',' Expression ( ',' Expression )? ')'
  def it_recognizes_regex_expression(production)
    lambda { parser(production).call(%q(REGEX ("foo"))) }.should raise_error
    parser(production).call(%q(REGEX ("foo", "bar"))).to_sxp.should == %q((regex "foo" "bar"))
  end

  # [59]    IRIrefOrFunction ::=       IRIref ArgList?
  def it_recognizes_iriref_or_function(production)
    it_recognizes_iriref(production)
    it_recognizes_function(production)
  end

  # [60] RDFLiteral
  def it_recognizes_rdf_literal_without_language_or_datatype(production)
    parser(production).call(%q("")).last.should == RDF::Literal.new("")
    parser(production).call(%q("foobar")).last.should == RDF::Literal.new("foobar")
    {
      :STRING_LITERAL1      => %q('foobar'),
      :STRING_LITERAL2      => %q("foobar"),
      :STRING_LITERAL_LONG1 => %q('''foobar'''),
      :STRING_LITERAL_LONG2 => %q("""foobar"""),
    }.each do |terminal, input|
      parser(production).call(input).last.should eql(RDF::Literal('foobar'))
    end
  end

  # [60] RDFLiteral
  def it_recognizes_rdf_literal_with_language(production)
    parser(production).call(%q(""@en)).last.should == RDF::Literal.new("", :language => :en)
    parser(production).call(%q("foobar"@en-US)).last.should == RDF::Literal.new("foobar", :language => :'en-us')
  end

  # [60] RDFLiteral
  def it_recognizes_rdf_literal_with_datatype(production)
    parser(production).call(%q(""^^<http://www.w3.org/2001/XMLSchema#string>)).last.should == RDF::Literal.new("", :datatype => RDF::XSD.string)
    parser(production).call(%q("foobar"^^<http://www.w3.org/2001/XMLSchema#string>)).last.should == RDF::Literal.new("foobar", :datatype => RDF::XSD.string)
  end

  # [61] NumericLiteral
  def it_recognizes_numeric_literal(production)
    parser(production).call(%q(123)).last.should     == RDF::Literal::Integer.new(123)
    parser(production).call(%q(+3.1415)).last.should == RDF::Literal::Decimal.new(3.1415)
    parser(production).call(%q(-1e6)).last.should    == RDF::Literal::Double.new(-1e6)
  end

  # [65] BooleanLiteral
  def it_recognizes_boolean_literal(production)
    parser(production).call(%q(true)).last.should == RDF::Literal(true)
    parser(production).call(%q(false)).last.should == RDF::Literal(false)
  end

  # [67] IRIref
  def it_recognizes_iriref(production)
    parser(production).call(%q(<http://example.org/>)).last.should == RDF::URI('http://example.org/')
    # XXXtest prefixed names
  end

  # [69] BlankNode
  def it_recognizes_blank_node(production)
    parser(production).call(%q(_:foobar)).last.should == SPARQL::Grammar::Parser.variable("foobar", false)
    parser(production).call(%q([])).last.should_not be_distinguished
  end

  # [74] VAR1
  def it_recognizes_var1(production)
    %w(foo bar).each do |input|
      parser(production).call("?#{input}").last.should == RDF::Query::Variable.new(input.to_sym)
    end
  end

  # [75] VAR2
  def it_recognizes_var2(production)
    %w(foo bar).each do |input|
      parser(production).call("$#{input}").last.should == RDF::Query::Variable.new(input.to_sym)
    end
  end

  # [92] NIL
  def it_recognizes_nil(production)
    parser(production).call(%q(())).last.should == RDF.nil
  end

  def bgp_patterns
    {
      # From sytax-sparql1/syntax-basic-03.rq
      %q(?x ?y ?z) => RDF::Query.new do
        pattern [RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y"), RDF::Query::Variable.new("z")]
      end,
      # From sytax-sparql1/syntax-basic-05.rq
      %q(?x ?y ?z . ?a ?b ?c) => RDF::Query.new do
        pattern [RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y"), RDF::Query::Variable.new("z")]
        pattern [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), RDF::Query::Variable.new("c")]
      end,
      # From sytax-sparql1/syntax-bnodes-01.rq
      %q([:p :q ]) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/q")]
      end,
      # From sytax-sparql1/syntax-bnodes-02.rq
      %q([] :p :q) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/q")]
      end,

      # From sytax-sparql2/syntax-general-01.rq
      %q(<a><b><c>) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/c")]
      end,
      # From sytax-sparql2/syntax-general-02.rq
      %q(<a><b>_:x) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), SPARQL::Grammar::Parser.variable("x", false)]
      end,
      # From sytax-sparql2/syntax-general-03.rq
      %q(<a><b>1) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal(1)]
      end,
      # From sytax-sparql2/syntax-general-04.rq
      %q(<a><b>+1) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal::Integer.new("+1")]
      end,
      # From sytax-sparql2/syntax-general-05.rq
      %q(<a><b>-1) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal::Integer.new("-1")]
      end,
      # From sytax-sparql2/syntax-general-06.rq
      %q(<a><b>1.0) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal::Decimal.new("1.0")]
      end,
      # From sytax-sparql2/syntax-general-07.rq
      %q(<a><b>+1.0) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal::Decimal.new("+1.0")]
      end,
      # From sytax-sparql2/syntax-general-08.rq
      %q(<a><b>-1.0) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal::Decimal.new("-1.0")]
      end,
      # From sytax-sparql2/syntax-general-09.rq
      %q(<a><b>1.0e0) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal::Double.new("1.0e0")]
      end,
      # From sytax-sparql2/syntax-general-10.rq
      %q(<a><b>+1.0e+1) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal::Double.new("+1.0e+1")]
      end,
      # From sytax-sparql2/syntax-general-11.rq
      %q(<a><b>-1.0e-1) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal::Double.new("-1.0e-1")]
      end,

      # Made up syntax tests
      %q(<a><b><c>,<d>) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/c")]
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/d")]
      end,
      %q(<a><b><c>;<d><e>) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/c")]
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/d"), RDF::URI("http://example.org/e")]
      end,
      %q([<b><c>,<d>]) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/c")]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/d")]
      end,
      %q([<b><c>;<d><e>]) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/c")]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.org/d"), RDF::URI("http://example.org/e")]
      end,
      %q((<a>)) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF["first"], RDF::URI("http://example.org/a")]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF["rest"], RDF["nil"]]
      end,
      %q((<a> <b>)) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF["first"], RDF::URI("http://example.org/a")]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF["rest"], SPARQL::Grammar::Parser.variable("1", false)]
        pattern [SPARQL::Grammar::Parser.variable("1", false), RDF["first"], RDF::URI("http://example.org/b")]
        pattern [SPARQL::Grammar::Parser.variable("1", false), RDF["rest"], RDF["nil"]]
      end,
      %q(<a><b>"foobar") => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal("foobar")]
      end,
      %q(<a><b>'foobar') => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal("foobar")]
      end,
      %q(<a><b>"""foobar""") => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal("foobar")]
      end,
      %q(<a><b>'''foobar''') => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal("foobar")]
      end,
      %q(<a><b>"foobar"@en) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal("foobar", :language => :en)]
      end,
      %q(<a><b>"foobar"^^<c>) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal("foobar", :datatype => RDF::URI("http://example.org/c"))]
      end,
      %q(<a><b>()) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF["nil"]]
      end,

      # From sytax-sparql1/syntax-bnodes-03.rq
      %q([ ?x ?y ] <http://example.com/p> [ ?pa ?b ]) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y")]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.com/p"), SPARQL::Grammar::Parser.variable("1", false)]
        pattern [SPARQL::Grammar::Parser.variable("1", false), RDF::Query::Variable.new("pa"), RDF::Query::Variable.new("b")]
      end,
      # From sytax-sparql1/syntax-bnodes-03.rq
      %q(_:a :p1 :q1 .
         _:a :p2 :q2 .) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("a", false), RDF::URI("http://example.com/p1"), RDF::URI("http://example.com/q1")]
        pattern [SPARQL::Grammar::Parser.variable("a", false), RDF::URI("http://example.com/p2"), RDF::URI("http://example.com/q2")]
      end,
      # From sytax-sparql1/syntax-forms-01.rq
      %q(( [ ?x ?y ] ) :p ( [ ?pa ?b ] 57 )) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("1", false), RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y")]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF["first"], SPARQL::Grammar::Parser.variable("1", false)]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF["rest"], RDF["nil"]]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.com/p"), SPARQL::Grammar::Parser.variable("2", false)]
        pattern [SPARQL::Grammar::Parser.variable("3", false), RDF::Query::Variable.new("pa"), RDF::Query::Variable.new("b")]
        pattern [SPARQL::Grammar::Parser.variable("2", false), RDF["first"], SPARQL::Grammar::Parser.variable("3", false)]
        pattern [SPARQL::Grammar::Parser.variable("2", false), RDF["rest"], SPARQL::Grammar::Parser.variable("4", false)]
        pattern [SPARQL::Grammar::Parser.variable("4", false), RDF["first"], RDF::Literal(57)]
        pattern [SPARQL::Grammar::Parser.variable("4", false), RDF["rest"], RDF["nil"]]
      end,
      # From sytax-sparql1/syntax-lists-01.rq
      %q(( ?x ) :p ?z) => RDF::Query.new do
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF["first"], RDF::Query::Variable.new("x")]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF["rest"], RDF["nil"]]
        pattern [SPARQL::Grammar::Parser.variable("0", false), RDF::URI("http://example.com/p"), RDF::Query::Variable.new("z")]
      end,
    }
  end
end

describe SPARQL::Grammar::Parser do
  extend  ProductionRequirements
  extend  ProductionExamples
  include ProductionRequirements
  include ProductionExamples

  describe "when matching the [1] Query production rule" do
    with_production(:Query) do |production|
      it_rejects_empty_input_using production

      {
        "BASE <foo/> SELECT * WHERE { <a> <b> <c> }" =>
          %q((base <foo/> (bgp (triple <a> <b> <c>)))),
        "PREFIX : <http://example.com/> SELECT * WHERE { :a :b :c }" =>
          %q((prefix ((: <http://example.com/>)) (bgp (triple :a :b :c)))),
        "PREFIX : <foo#> PREFIX bar: <bar#> SELECT * WHERE { :a :b bar:c }" =>
          %q((prefix ((: <foo#>) (bar: <bar#>)) (bgp (triple :a :b bar:c)))),
        "BASE <http://baz/> PREFIX : <http://foo#> PREFIX bar: <http://bar#> SELECT * WHERE { <a> :b bar:c }" =>
        %q((base <http://baz/> (prefix ((: <http://foo#>) (bar: <http://bar#>)) (bgp (triple <a> :b bar:c))))),
      }.each_pair do |input, result|
        given_it_generates(production, input, result, :resolve_uris => false)
      end

      {
        "BASE <foo/> SELECT * WHERE { <a> <b> <c> }" =>
          RDF::Query.new { pattern [RDF::URI("foo/a"), RDF::URI("foo/b"), RDF::URI("foo/c")]},
        "PREFIX : <http://example.com/> SELECT * WHERE { :a :b :c }" =>
          RDF::Query.new { pattern [RDF::URI("http://example.com/a"), RDF::URI("http://example.com/b"), RDF::URI("http://example.com/c")]},
        "PREFIX : <foo#> PREFIX bar: <bar#> SELECT * WHERE { :a :b bar:c }" =>
          RDF::Query.new { pattern [RDF::URI("foo#a"), RDF::URI("foo#b"), RDF::URI("bar#c")]},
        "BASE <http://baz/> PREFIX : <http://foo#> PREFIX bar: <http://bar#> SELECT * WHERE { <a> :b bar:c }" =>
          RDF::Query.new { pattern [RDF::URI("http://baz/a"), RDF::URI("http://foo#b"), RDF::URI("http://bar#c")]},
      }.each_pair do |input, result|
        given_it_generates(production, input, result, :resolve_uris => true)
      end

      bgp_patterns.each_pair do |input, result|
        given_it_generates(production, "SELECT * WHERE {#{input}}", result,
          :prefixes => {nil => "http://example.com/", :rdf => RDF.to_uri.to_s},
          :base_uri => RDF::URI("http://example.org/"),
          :anon_base => "b0")
      end

      given_it_generates(production, "SELECT * FROM <a> WHERE {?a ?b ?c}", %q((dataset (<a>) (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "SELECT * FROM NAMED <a> WHERE {?a ?b ?c}", %q((dataset ((named <a>)) (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "SELECT * WHERE {?a ?b ?c}", %q((bgp (triple ?a ?b ?c))))
      given_it_generates(production, "SELECT * WHERE {GRAPH <a> {?a ?b ?c}}", %q((graph <a> (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "SELECT * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      given_it_generates(production, "SELECT * WHERE {?a ?b ?c {?d ?e ?f}}", %q((join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      given_it_generates(production, "SELECT * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))

      describe "Var+" do
        given_it_generates(production, "SELECT ?a ?b WHERE {?a ?b ?c}", %q((project (?a ?b) (bgp (triple ?a ?b ?c)))))
      end

      describe "DISTINCT" do
        given_it_generates(production, "SELECT DISTINCT * WHERE {?a ?b ?c}", %q((distinct (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "SELECT DISTINCT ?a ?b WHERE {?a ?b ?c}", %q((distinct (project (?a ?b) (bgp (triple ?a ?b ?c))))))
      end

      describe "REDUCED" do
        given_it_generates(production, "SELECT REDUCED * WHERE {?a ?b ?c}", %q((reduced (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "SELECT REDUCED ?a ?b WHERE {?a ?b ?c}", %q((reduced (project (?a ?b) (bgp (triple ?a ?b ?c))))))
      end
      
      describe "FILTER" do
        given_it_generates(production, "SELECT * WHERE {?a ?b ?c FILTER (?a)}", %q((filter ?a (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "SELECT * WHERE {FILTER (?a) ?a ?b ?c}", %q((filter ?a (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "SELECT * WHERE { FILTER (?o>5) . ?s ?p ?o }", %q((filter (> ?o 5) (bgp (triple ?s ?p ?o)))))
      end

      given_it_generates(production, "CONSTRUCT {?a ?b ?c} FROM <a> WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (dataset (<a>) (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} FROM NAMED <a> WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (dataset ((named <a>)) (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {GRAPH <a> {?a ?b ?c}}", %q((construct ((triple ?a ?b ?c)) (graph <a> (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}", %q((construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c))))))

      given_it_generates(production, "DESCRIBE * FROM <a> WHERE {?a ?b ?c}", %q((describe () (dataset (<a>) (bgp (triple ?a ?b ?c))))))

      given_it_generates(production, "ASK WHERE {GRAPH <a> {?a ?b ?c}}", %q((ask (graph <a> (bgp (triple ?a ?b ?c))))))
    end
  end

  describe "when matching the [2] Prologue production rule" do
    with_production(:Prologue) do |production|
      it "sets base_uri to <http://example.org> given 'BASE <http://example.org/>'" do
        p = parser(nil, :resolve_uris => true).call(%q(BASE <http://example.org/>))
        p.parse(production)
        p.base_uri.should == RDF::URI('http://example.org/')
      end

      given_it_generates(production, %q(BASE <http://example.org/>), [:BaseDecl, RDF::URI("http://example.org/")], :resolve_uris => false)

      it "sets prefix : to 'foobar' given 'PREFIX : <foobar>'" do
        p = parser(nil, :resolve_uris => true).call(%q(PREFIX : <foobar>))
        p.parse(production)
        p.prefix(nil).should == 'foobar'
        p.prefixes[nil].should == 'foobar'
      end

      given_it_generates(production, %q(PREFIX : <foobar>), [:PrefixDecl, [[:":", RDF::URI("foobar")]]], :resolve_uris => false)

      it "sets prefix foo: to 'bar' given 'PREFIX foo: <bar>'" do
        p = parser(nil, :resolve_uris => true).call(%q(PREFIX foo: <bar>))
        p.parse(production)
        p.prefix(:foo).should == 'bar'
        p.prefix("foo").should == 'bar'
        p.prefixes[:foo].should == 'bar'
      end

      given_it_generates(production, %q(PREFIX foo: <bar>), [:PrefixDecl, [[:"foo:", RDF::URI("bar")]]], :resolve_uris => false)

      given_it_generates(production, %q(PREFIX : <foobar> PREFIX foo: <bar>),
        [:PrefixDecl, [
          [:":", RDF::URI("foobar")],
          [:"foo:", RDF::URI("bar")]]], :resolve_uris => false);
    end
  end

  # [5]     SelectQuery               ::=       'SELECT' ( 'DISTINCT' | 'REDUCED' )? ( Var+ | '*' ) DatasetClause* WhereClause SolutionModifier
  describe "when matching the [5] SelectQuery production rule" do
    with_production(:SelectQuery) do |production|
      describe "SELECT * WHERE {...}" do
        bgp_patterns.each_pair do |input, result|
          given_it_generates(production, "SELECT * WHERE {#{input}}", result,
            :prefixes => {nil => "http://example.com/", :rdf => RDF.to_uri.to_s},
            :base_uri => RDF::URI("http://example.org/"))
        end
      end
      given_it_generates(production, "SELECT * FROM <a> WHERE {?a ?b ?c}", %q((dataset (<a>) (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "SELECT * FROM NAMED <a> WHERE {?a ?b ?c}", %q((dataset ((named <a>)) (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "SELECT * WHERE {?a ?b ?c}", %q((bgp (triple ?a ?b ?c))))
      given_it_generates(production, "SELECT * WHERE {GRAPH <a> {?a ?b ?c}}", %q((graph <a> (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "SELECT * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      given_it_generates(production, "SELECT * WHERE {?a ?b ?c {?d ?e ?f}}", %q((join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      given_it_generates(production, "SELECT * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      given_it_generates(production, "SELECT * {GRAPH ?g { :x :b ?a . GRAPH ?g2 { :x :p ?x } }}",
        %q((graph ?g
            (join
              (bgp (triple <x> <b> ?a))
              (graph ?g2
                (bgp (triple <x> <p> ?x)))))))

      describe "Var+" do
        given_it_generates(production, "SELECT ?a ?b WHERE {?a ?b ?c}", %q((project (?a ?b) (bgp (triple ?a ?b ?c)))))
      end

      describe "DISTINCT" do
        given_it_generates(production, "SELECT DISTINCT * WHERE {?a ?b ?c}", %q((distinct (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "SELECT DISTINCT ?a ?b WHERE {?a ?b ?c}", %q((distinct (project (?a ?b) (bgp (triple ?a ?b ?c))))))
      end

      describe "REDUCED" do
        given_it_generates(production, "SELECT REDUCED * WHERE {?a ?b ?c}", %q((reduced (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "SELECT REDUCED ?a ?b WHERE {?a ?b ?c}", %q((reduced (project (?a ?b) (bgp (triple ?a ?b ?c))))))
      end
      
      describe "FILTER" do
        given_it_generates(production, "SELECT * WHERE {?a ?b ?c FILTER (?a)}", %q((filter ?a (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "SELECT * WHERE {FILTER (?a) ?a ?b ?c}", %q((filter ?a (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "SELECT * WHERE { FILTER (?o>5) . ?s ?p ?o }", %q((filter (> ?o 5) (bgp (triple ?s ?p ?o)))))
      end
    end
  end

  # [6]     ConstructQuery            ::=       'CONSTRUCT' ConstructTemplate DatasetClause* WhereClause SolutionModifier
  describe "when matching the [6] ConstructQuery production rule" do
    with_production(:ConstructQuery) do |production|
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} FROM <a> WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (dataset (<a>) (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} FROM NAMED <a> WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (dataset ((named <a>)) (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "CONSTRUCT {[?b ?c]} WHERE {?a ?b ?c}", %q((construct ((triple _:b0 ?b ?c)) (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {GRAPH <a> {?a ?b ?c}}", %q((construct ((triple ?a ?b ?c)) (graph <a> (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}", %q((construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "CONSTRUCT {} WHERE {}", %q((construct () (bgp))))
    end
  end

  describe "when matching the [7] DescribeQuery production rule" do
    with_production(:DescribeQuery) do |production|
      given_it_generates(production, "DESCRIBE * FROM <a> WHERE {?a ?b ?c}", %q((describe () (dataset (<a>) (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "DESCRIBE * FROM <a> WHERE {?a ?b ?c}", %q((describe () (dataset (<a>) (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "DESCRIBE * FROM NAMED <a> WHERE {?a ?b ?c}", %q((describe () (dataset ((named <a>))(bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "DESCRIBE * WHERE {?a ?b ?c}", %q((describe () (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "DESCRIBE * WHERE {GRAPH <a> {?a ?b ?c}}", %q((describe () (graph <a> (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "DESCRIBE * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((describe () (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "DESCRIBE * WHERE {?a ?b ?c {?d ?e ?f}}", %q((describe () (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "DESCRIBE * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((describe () (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "DESCRIBE * WHERE {?a ?b ?c FILTER (?a)}", %q((describe () (filter ?a (bgp (triple ?a ?b ?c))))))

      describe "No Query" do
        given_it_generates(production, "DESCRIBE *", %q((describe () (bgp))))
        given_it_generates(production, "DESCRIBE ?a", %q((describe (?a) (bgp))))
        given_it_generates(production, "DESCRIBE * FROM <a>", %q((describe () (dataset (<a>) (bgp)))))
      end

      describe "VarOrIRIref+" do
        given_it_generates(production, "DESCRIBE <a> WHERE {?a ?b ?c}", %q((describe (<a>) (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "DESCRIBE ?a <a> WHERE {?a ?b ?c}", %q((describe (?a <a>) (bgp (triple ?a ?b ?c)))))
        given_it_generates(production, "DESCRIBE ?a ?b WHERE {?a ?b ?c}", %q((describe (?a ?b) (bgp (triple ?a ?b ?c)))))
      end
    end
  end

  describe "when matching the [8] AskQuery production rule" do
    with_production(:AskQuery) do |production|
      given_it_generates(production, "ASK FROM <a> WHERE {?a ?b ?c}", %q((ask (dataset (<a>) (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "ASK FROM NAMED <a> WHERE {?a ?b ?c}", %q((ask (dataset ((named <a>))(bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "ASK WHERE {?a ?b ?c}", %q((ask (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "ASK WHERE {GRAPH <a> {?a ?b ?c}}", %q((ask (graph <a> (bgp (triple ?a ?b ?c))))))
      given_it_generates(production, "ASK WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((ask (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "ASK WHERE {?a ?b ?c {?d ?e ?f}}", %q((ask (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "ASK WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((ask (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))))
      given_it_generates(production, "ASK WHERE {?a ?b ?c FILTER (?a)}", %q((ask (filter ?a (bgp (triple ?a ?b ?c))))))
    end
  end

  describe "when matching the [9] DatasetClause production rule" do
    with_production(:DatasetClause) do |production|
      it_rejects_empty_input_using production
      given_it_generates(production, %q(FROM <http://example.org/foaf/aliceFoaf>), [:dataset, RDF::URI("http://example.org/foaf/aliceFoaf")])
      given_it_generates(production, %q(FROM NAMED <http://example.org/foaf/aliceFoaf>), [:dataset, [:named, RDF::URI("http://example.org/foaf/aliceFoaf")]])
    end
  end

  # No specs for the following, as nothing is produced in SSE.
  #   [10] DefaultGraphClause
  #   [11] NamedGraphClause
  #   [12] SourceSelector
  describe "when matching the [13] WhereClause production rule" do
    with_production(:WhereClause) do |production|
      it_rejects_empty_input_using production

      bgp_patterns.each_pair do |input, result|
        given_it_generates(production, "WHERE {#{input}}", result,
          :prefixes => {nil => "http://example.com/", :rdf => RDF.to_uri.to_s},
          :base_uri => RDF::URI("http://example.org/"),
          :anon_base => "b0")
      end

      given_it_generates(production, "WHERE {?a ?b ?c}", %q((bgp (triple ?a ?b ?c))))
      given_it_generates(production, "WHERE {GRAPH <a> {?a ?b ?c}}", %q((graph <a> (bgp (triple ?a ?b ?c)))))
      given_it_generates(production, "WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      given_it_generates(production, "WHERE {?a ?b ?c {?d ?e ?f}}", %q((join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      given_it_generates(production, "WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      given_it_generates(production, "WHERE {?a ?b ?c FILTER (?a)}", %q((filter ?a (bgp (triple ?a ?b ?c)))))
    end
  end

  # [14]    SolutionModifier          ::=       OrderClause? LimitOffsetClauses?
  describe "when matching the [14] SolutionModifier production rule" do
    with_production(:SolutionModifier) do |production|
      it_rejects_empty_input_using production

      given_it_generates(production, "LIMIT 1", [:slice, :_, RDF::Literal(1)])
      given_it_generates(production, "OFFSET 1", [:slice, RDF::Literal(1), :_])
      given_it_generates(production, "LIMIT 1 OFFSET 2", [:slice, RDF::Literal(2), RDF::Literal(1)])
      given_it_generates(production, "OFFSET 2 LIMIT 1", [:slice, RDF::Literal(2), RDF::Literal(1)])

      given_it_generates(production, "ORDER BY ASC (1)", [:order, [SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1))]])
      given_it_generates(production, "ORDER BY DESC (?a)", [:order, [SPARQL::Algebra::Operator::Desc.new(RDF::Query::Variable.new("a"))]])
      given_it_generates(production, "ORDER BY ?a ?b ?c", [:order, [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), RDF::Query::Variable.new("c")]])
      given_it_generates(production, "ORDER BY ?a ASC (1) isURI(<b>)", [:order, [RDF::Query::Variable.new("a"), SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1)), SPARQL::Algebra::Operator::IsURI.new(RDF::URI("b"))]])
      
      # Can't test both together, as they are handled individually in [5] SelectQuery
    end
  end

  # [15]    LimitOffsetClauses        ::=       ( LimitClause OffsetClause? | OffsetClause LimitClause? )
  describe "when matching the [15] LimitOffsetClauses production rule" do
    with_production(:LimitOffsetClauses) do |production|
      given_it_generates(production, "LIMIT 1", [:slice, :_, RDF::Literal(1)])
      given_it_generates(production, "OFFSET 1", [:slice, RDF::Literal(1), :_])
      given_it_generates(production, "LIMIT 1 OFFSET 2", [:slice, RDF::Literal(2), RDF::Literal(1)])
      given_it_generates(production, "OFFSET 2 LIMIT 1", [:slice, RDF::Literal(2), RDF::Literal(1)])
    end
  end

  # [16]    OrderClause               ::=       'ORDER' 'BY' OrderCondition+
  describe "when matching the [16] OrderClause production rule" do
    with_production(:OrderClause) do |production|
      given_it_generates(production, "ORDER BY ASC (1)", [:order, [SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1))]])
      given_it_generates(production, "ORDER BY DESC (?a)", [:order, [SPARQL::Algebra::Operator::Desc.new(RDF::Query::Variable.new("a"))]])
      given_it_generates(production, "ORDER BY ?a ?b ?c", [:order, [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), RDF::Query::Variable.new("c")]])
      given_it_generates(production, "ORDER BY ?a ASC (1) isURI(<b>)", [:order, [RDF::Query::Variable.new("a"), SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1)), SPARQL::Algebra::Operator::IsURI.new(RDF::URI("b"))]])
    end
  end

  # [17]    OrderCondition            ::=       ( ( 'ASC' | 'DESC' ) BrackettedExpression ) | ( Constraint | Var )
  describe "when matching the [17] OrderCondition production rule" do
    with_production(:OrderCondition) do |production|
      given_it_generates(production, "ASC (1)", [:OrderCondition, SPARQL::Algebra::Expression[:asc, RDF::Literal(1)]])
      given_it_generates(production, "DESC (?a)", [:OrderCondition, SPARQL::Algebra::Expression[:desc, RDF::Query::Variable.new("a")]])

      # Constraint
      it_recognizes_bracketted_expression_using production
      it_recognizes_built_in_call_using production
      it_recognizes_function_using production

      it_recognizes_var_using production
    end
  end

  describe "when matching the [18] LimitClause production rule" do
    with_production(:LimitClause) do |production|
      it "recognizes LIMIT clauses" do
        parser(production).call(%q(LIMIT 10)).should == [:limit, RDF::Literal.new(10)]
      end
    end
  end

  describe "when matching the [19] OffsetClause production rule" do
    with_production(:OffsetClause) do |production|
      it "recognizes OFFSET clauses" do
        parser(production).call(%q(OFFSET 10)).should == [:offset, RDF::Literal(10)]
      end
    end
  end

  # [20]    GroupGraphPattern         ::=       '{' TriplesBlock? ( ( GraphPatternNotTriples | Filter ) '.'? TriplesBlock? )* '}'
  describe "when matching the [20] GroupGraphPattern production rule" do
    with_production(:GroupGraphPattern) do |production|
      {
        # From data/Optional/q-opt-1.rq
        "{<a><b><c> OPTIONAL {<d><e><f>}}" =>
          %q((leftjoin
            (bgp (triple <a> <b> <c>))
            (bgp (triple <d> <e> <f>)))),
        "{OPTIONAL {<d><e><f>}}" =>
          %q((leftjoin
            (bgp)
            (bgp (triple <d> <e> <f>)))),
        # From data/Optional/q-opt-2.rq
        "{<a><b><c> OPTIONAL {<d><e><f>} OPTIONAL {<g><h><i>}}" =>
          %q((leftjoin
              (leftjoin
                (bgp (triple <a> <b> <c>))
                (bgp (triple <d> <e> <f>)))
              (bgp (triple <g> <h> <i>)))),
        "{<a><b><c> {:x :y :z} {<d><e><f>}}" =>
          %q((join
              (join
                (bgp (triple <a> <b> <c>))
                (bgp (triple <x> <y> <z>)))
              (bgp (triple <d> <e> <f>)))),
        "{<a><b><c> {:x :y :z} <d><e><f>}" =>
          %q((join
              (join
                (bgp (triple <a> <b> <c>))
                (bgp (triple <x> <y> <z>)))
              (bgp (triple <d> <e> <f>)))),
        # From data/extracted-examples/query-4.1-q1.rq
       "{{:x :y :z} {<d><e><f>}}" =>
          %q((join
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))),
        "{<a><b><c> {:x :y :z} UNION {<d><e><f>}}" =>
          %q((join
              (bgp (triple <a> <b> <c>))
              (union
                (bgp (triple <x> <y> <z>))
                (bgp (triple <d> <e> <f>))))),
        # From data/Optional/q-opt-3.rq
        "{{:x :y :z} UNION {<d><e><f>}}" =>
          %q((union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))),
        "{GRAPH ?src { :x :y :z}}" => %q((graph ?src (bgp (triple <x> <y> <z>)))),
        "{<a><b><c> GRAPH <graph> {<d><e><f>}}" =>
          %q((join
              (bgp (triple <a> <b> <c>))
              (graph <graph>
                (bgp (triple <d> <e> <f>))))),
        "{ ?a :b ?c .  OPTIONAL { ?c :d ?e } . FILTER (! bound(?e))}" =>
          %q((filter (! (bound ?e))
              (leftjoin
                (bgp (triple ?a <b> ?c))
                (bgp (triple ?c <d> ?e))))),
        # From data/Expr1/expr-2
        "{ ?book dc:title ?title . 
          OPTIONAL
            { ?book x:price ?price . 
              FILTER (?price < 15) .
            } .
        }" => %q((leftjoin (bgp (triple ?book <title> ?title)) (bgp (triple ?book <price> ?price)) (< ?price 15))),
        # From data-r2/filter-nested-2
        "{ :x :p ?v . { FILTER(?v = 1) } }" =>
          %q((join
            (bgp (triple <x> <p> ?v))
            (filter (= ?v 1)
              (bgp)))),
        "{FILTER (?v = 2) FILTER (?w = 3) ?s :p ?v . ?s :q ?w . }" =>
          %q((filter (exprlist (= ?v 2) (= ?w 3))
            (bgp
              (triple ?s <p> ?v)
              (triple ?s <q> ?w)
            ))),
      }.each_pair do |input, result|
        given_it_generates(production, input, result, :resolve_uris => false)
      end
    end
  end

  # [21]    TriplesBlock              ::=       TriplesSameSubject ( '.' TriplesBlock? )?
  describe "when matching the [21] TriplesBlock production rule" do
    with_production(:TriplesBlock) do |production|
      bgp_patterns.each_pair do |input, result|
        given_it_generates(production, input, result,
          :prefixes => {nil => "http://example.com/", :rdf => RDF.to_uri.to_s},
          :base_uri => RDF::URI("http://example.org/"),
          :anon_base => "b0")
      end
    end
  end

  # [22] GraphPatternNotTriples ::= OptionalGraphPattern | GroupOrUnionGraphPattern | GraphGraphPattern
  describe "when matching the [22] GraphPatternNotTriples production rule" do
    with_production(:GraphPatternNotTriples) do |production|
      it_rejects_empty_input_using production
      {
        # OptionalGraphPattern
        "OPTIONAL {<d><e><f>}" => %q((leftjoin placeholder (bgp (triple <d> <e> <f>)))),

        # GroupOrUnionGraphPattern
        "{:x :y :z}" => %q((bgp (triple <x> <y> <z>))),
        "{:x :y :z} UNION {<d><e><f>}" =>
          %q((union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))),
        "{:x :y :z} UNION {<d><e><f>} UNION {?a ?b ?c}" =>
          %q((union
              (union
                (bgp (triple <x> <y> <z>))
                (bgp (triple <d> <e> <f>)))
              (bgp (triple ?a ?b ?c)))),

        # GraphGraphPattern
        "GRAPH ?a {<d><e><f>}" => %q((graph ?a (bgp (triple <d> <e> <f>)))),
        "GRAPH :a {<d><e><f>}" => %q((graph <a> (bgp (triple <d> <e> <f>)))),
        "GRAPH <a> {<d><e><f>}" => %q((graph <a> (bgp (triple <d> <e> <f>)))),
      }.each_pair do |input, result|
        given_it_generates(production, input, result)
      end
    end
  end

  # [23]    OptionalGraphPattern      ::=       'OPTIONAL' GroupGraphPattern
  describe "when matching the [23] OptionalGraphPattern production rule" do
    with_production(:OptionalGraphPattern) do |production|
      it_rejects_empty_input_using production
      {
        "OPTIONAL {<d><e><f>}" => %q((leftjoin placeholder (bgp (triple <d> <e> <f>)))).to_sym,
        "OPTIONAL {?book :price ?price . FILTER (?price < 15)}" =>
          %q((leftjoin placeholder (bgp (triple ?book :price ?price)) (< ?price 15))).to_sym,
        %q(OPTIONAL {?y :q ?w . FILTER(?v=2) FILTER(?w=3)}) =>
          %q((leftjoin placeholder (bgp (triple ?y :q ?w)) (exprlist (= ?v 2) (= ?w 3)))).to_sym,
      }.each_pair do |input, result|
        given_it_generates(production, input, result, :resolve_uris => false)
      end
    end
  end

  # [24]    GraphGraphPattern         ::=       'GRAPH' VarOrIRIref GroupGraphPattern
  describe "when matching the [24] GraphGraphPattern production rule" do
    with_production(:GraphGraphPattern) do |production|
      it_rejects_empty_input_using production

      {
        "GRAPH ?a {<d><e><f>}" => %q((graph ?a (bgp (triple <d> <e> <f>)))),
        "GRAPH :a {<d><e><f>}" => %q((graph <a> (bgp (triple <d> <e> <f>)))),
        "GRAPH <a> {<d><e><f>}" => %q((graph <a> (bgp (triple <d> <e> <f>)))),
      }.each_pair do |input, result|
        given_it_generates(production, input, result, :resolve_uris => false)
      end
    end
  end

  # [25]    GroupOrUnionGraphPattern  ::=       GroupGraphPattern ( 'UNION' GroupGraphPattern )*
  describe "when matching the [25] GroupOrUnionGraphPattern production rule" do
    with_production(:GroupOrUnionGraphPattern) do |production|
      it_rejects_empty_input_using production

      {
        # From data/Optional/q-opt-3.rq
        "{:x :y :z}" => %q((bgp (triple <x> <y> <z>))),
        "{:x :y :z} UNION {<d><e><f>}" =>
          %q((union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))),
        "{:x :y :z} UNION {<d><e><f>} UNION {?a ?b ?c}" =>
          %q((union
              (union
                (bgp (triple <x> <y> <z>))
                (bgp (triple <d> <e> <f>)))
              (bgp (triple ?a ?b ?c)))),
      }.each_pair do |input, result|
        given_it_generates(production, input, result, :resolve_uris => false)
      end
    end
  end

  # [26]    Filter                    ::=       'FILTER' Constraint
  describe "when matching the [26] Filter production rule" do
    with_production(:Filter) do |production|
      # Can't test against SSE, as filter also requires a BGP or other query operator
      given_it_generates(production, %(FILTER (1)), [:filter, RDF::Literal(1)])
      given_it_generates(production, %(FILTER ((1))), [:filter, RDF::Literal(1)])
      given_it_generates(production, %(FILTER ("foo")), [:filter, RDF::Literal("foo")])
      given_it_generates(production, %(FILTER STR ("foo")), [:filter, SPARQL::Algebra::Expression[:str, RDF::Literal("foo")]])
      given_it_generates(production, %(FILTER LANGMATCHES ("foo", "bar")), [:filter, SPARQL::Algebra::Expression[:langmatches, RDF::Literal("foo"), RDF::Literal("bar")]])
      given_it_generates(production, %(FILTER isIRI ("foo")), [:filter, SPARQL::Algebra::Expression[:isIRI, RDF::Literal("foo")]])
      given_it_generates(production, %(FILTER REGEX ("foo", "bar")), [:filter, SPARQL::Algebra::Expression[:regex, RDF::Literal("foo"), RDF::Literal("bar")]])
      given_it_generates(production, %(FILTER <fun> ("arg")), [:filter, [RDF::URI("fun"), RDF::Literal("arg")]])
      given_it_generates(production, %(FILTER BOUND (?e)), [:filter, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]])
      given_it_generates(production, %(FILTER (BOUND (?e))), [:filter, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]])
      given_it_generates(production, %(FILTER (! BOUND (?e))), [:filter, SPARQL::Algebra::Expression[:not, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]]])
    end
  end

  # [27] Constraint ::=  BrackettedExpression | BuiltInCall | FunctionCall
  describe "when matching the [27] Constraint production rule" do
    with_production(:Constraint) do |production|
      it_rejects_empty_input_using production
      it_recognizes_bracketted_expression_using production
      it_recognizes_built_in_call_using production
      it_recognizes_function_using production
    end
  end

  describe "when matching the [28] FunctionCall production rule" do
    with_production(:FunctionCall) do |production|
      it_recognizes_function_using production
    end
  end

  describe "when matching the [29] ArgList production rule" do
    with_production(:ArgList) do |production|
      it_recognizes_nil_using production

      given_it_generates(production, %q(()), [:ArgList, RDF["nil"]])
      given_it_generates(production, %q(("foo")), [:ArgList, RDF::Literal("foo")])
      given_it_generates(production, %q(("foo", "bar")), [:ArgList, RDF::Literal("foo"), RDF::Literal("bar")])
    end
  end

  describe "when matching the [30] ConstructTemplate production rule" do
    with_production(:ConstructTemplate) do |production|
      {
        # From sytax-sparql1/syntax-basic-03.rq
        %q(?x ?y ?z) => RDF::Query.new do
          pattern [RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y"), RDF::Query::Variable.new("z")]
        end,
        # From sytax-sparql1/syntax-basic-05.rq
        %q(?x ?y ?z . ?a ?b ?c) => RDF::Query.new do
          pattern [RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y"), RDF::Query::Variable.new("z")]
          pattern [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), RDF::Query::Variable.new("c")]
        end,
        # From sytax-sparql1/syntax-bnodes-01.rq
        %q([:p :q ]) => RDF::Query.new do
          pattern [RDF::Node.new("b0"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/q")]
        end,
        # From sytax-sparql1/syntax-bnodes-02.rq
        %q([] :p :q) => RDF::Query.new do
          pattern [RDF::Node.new("b0"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/q")]
        end,

        # From sytax-sparql2/syntax-general-01.rq
        %q(<a><b><c>) => RDF::Query.new do
          pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/c")]
        end,
        # From sytax-sparql2/syntax-general-02.rq
        %q(<a><b>_:x) => RDF::Query.new do
          pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Node("x")]
        end,
      }.each_pair do |input, result|
        given_it_generates(production, "{#{input}}", ([:ConstructTemplate] + result.patterns),
          :prefixes => {nil => "http://example.com/", :rdf => RDF.to_uri.to_s},
          :base_uri => RDF::URI("http://example.org/"),
          :anon_base => "b0")
      end
    end
  end

  # Not testing [31] ConstructTriples

  # Productions that can be tested individually
  describe "individual nonterminal productions" do
    describe "when matching the [41] GraphNode production rule" do
      with_production(:GraphNode) do |production|
        it_recognizes_graph_node_using(production)
      end
    end

    describe "when matching the [42] VarOrTerm production rule" do
      with_production(:VarOrTerm) do |production|
        it_recognizes_var_or_term_using production
      end
    end

    describe "when matching the [43] VarOrIRIref production rule" do
      with_production(:VarOrIRIref) do |production|
        it_recognizes_var_or_iriref_using production
      end
    end

    describe "when matching the [44] Var production rule" do
      with_production(:Var) do |production|
        it_rejects_empty_input_using production

        it "recognizes the VAR1 terminal" do
          it_recognizes_var1(production)
        end

        it "recognizes the VAR2 terminal" do
          it_recognizes_var2(production)
        end
      end
    end

    describe "when matching the [45] GraphTerm production rule" do
      with_production(:GraphTerm) do |production|
        it_recognizes_graph_term_using(production)
      end
    end

    describe "when matching the [46] Expression production rule" do
      with_production(:Expression) do |production|
        it_recognizes_expression_using production
      end
    end

    describe "when matching the [47] ConditionalOrExpression production rule" do
      with_production(:ConditionalOrExpression) do |production|
        it_recognizes_conditional_or_expression_using production
      end
    end

    describe "when matching the [48] ConditionalAndExpression production rule" do
      with_production(:ConditionalAndExpression) do |production|
        it_recognizes_conditional_and_expression_using production
      end
    end

    describe "when matching the [49] ValueLogical production rule" do
      with_production(:ValueLogical) do |production|
        it_recognizes_value_logical_using production
      end
    end

    describe "when matching the [50] RelationalExpression production rule" do
      with_production(:RelationalExpression) do |production|
        it_recognizes_relational_expression_using production
      end
    end

    describe "when matching the [51] NumericExpression production rule" do
      with_production(:NumericExpression) do |production|
        it_recognizes_numeric_expression_using production
      end
    end

    describe "when matching the [52] AdditiveExpression production rule" do
      with_production(:AdditiveExpression) do |production|
        it_recognizes_additive_expression_using production
      end
    end

    describe "when matching the [53] MultiplicativeExpression production rule" do
      with_production(:MultiplicativeExpression) do |production|
        it_recognizes_multiplicative_expression_using production
      end
    end

    describe "when matching the [54] UnaryExpression production rule" do
      with_production(:UnaryExpression) do |production|
        it_recognizes_unary_expression_using production
      end
    end

    describe "when matching the [55] PrimaryExpression production rule" do
      # [55] PrimaryExpression ::= BrackettedExpression | BuiltInCall | IRIrefOrFunction | RDFLiteral | NumericLiteral | BooleanLiteral | Var
      with_production(:PrimaryExpression) do |production|
        it_recognizes_primary_expression_using production
      end
    end

    describe "when matching the [56] BrackettedExpression production rule" do
      with_production(:BrackettedExpression) do |production|
        it_recognizes_bracketted_expression_using production
      end
    end

    describe "when matching the [57] BuiltInCall production rule" do
      with_production(:BuiltInCall) do |production|
        it_recognizes_built_in_call_using production
      end
    end

    describe "when matching the [58] RegexExpression production rule" do
      with_production(:RegexExpression) do |production|
        it_recognizes_regex_expression_using production
      end
    end

    describe "when matching the [59] IRIrefOrFunction production rule" do
      with_production(:IRIrefOrFunction) do |production|
        it_recognizes_iriref_or_function_using production
      end
    end

    describe "when matching the [60] RDFLiteral production rule" do
      with_production(:RDFLiteral) do |production|
        it_rejects_empty_input_using production

        it "recognizes plain literals" do
          it_recognizes_rdf_literal_without_language_or_datatype production
        end

        it "recognizes language-tagged literals" do
          it_recognizes_rdf_literal_with_language production
        end

        it "recognizes datatyped literals" do
          it_recognizes_rdf_literal_with_datatype production
        end

      end
    end

    describe "when matching the [61] NumericLiteral production rule" do
      with_production(:NumericLiteral) do |production|
        it_rejects_empty_input_using production
        it_recognizes_numeric_literal_using production

        it "recognizes the NumericLiteralUnsigned nonterminal" do
          parser(production).call(%q(123)).last.should     eql RDF::Literal::Integer.new("123")
          parser(production).call(%q(3.1415)).last.should  eql RDF::Literal::Decimal.new("3.1415")
          parser(production).call(%q(1e6)).last.should     eql RDF::Literal::Double.new("1e6")
        end

        it "recognizes the NumericLiteralPositive nonterminal" do
          parser(production).call(%q(+123)).last.should    eql RDF::Literal::Integer.new("+123")
          parser(production).call(%q(+3.1415)).last.should eql RDF::Literal::Decimal.new("+3.1415")
          parser(production).call(%q(+1e6)).last.should    eql RDF::Literal::Double.new("+1e6")
        end

        it "recognizes the NumericLiteralNegative nonterminal" do
          parser(production).call(%q(-123)).last.should    eql RDF::Literal::Integer.new("-123")
          parser(production).call(%q(-3.1415)).last.should eql RDF::Literal::Decimal.new("-3.1415")
          parser(production).call(%q(-1e6)).last.should    eql RDF::Literal::Double.new("-1e6")
        end
      end
    end

    describe "when matching the [62] NumericLiteralUnsigned production rule" do
      with_production(:NumericLiteralUnsigned) do |production|
        it_rejects_empty_input_using production

        it "recognizes the INTEGER terminal" do
          %w(1 2 3 42 123).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Integer.new(input)
          end
        end

        it "recognizes the DECIMAL terminal" do
          %w(1. 3.1415 .123).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Decimal.new(input)
          end
        end

        it "recognizes the DOUBLE terminal" do
          %w(1e2 3.1415e2 .123e2).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Double.new(input)
          end
        end
      end
    end

    describe "when matching the [63] NumericLiteralPositive production rule" do
      with_production(:NumericLiteralPositive) do |production|
        it "recognizes the INTEGER_POSITIVE terminal" do
          %w(+1 +2 +3 +42 +123).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Integer.new(input)
          end
        end

        it "recognizes the DECIMAL_POSITIVE terminal" do
          %w(+1. +3.1415 +.123).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Decimal.new(input)
          end
        end

        it "recognizes the DOUBLE_POSITIVE terminal" do
          %w(+1e2 +3.1415e2 +.123e2).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Double.new(input)
          end
        end
      end
    end

    describe "when matching the [64] NumericLiteralNegative production rule" do
      with_production(:NumericLiteralNegative) do |production|
        it "recognizes the INTEGER_NEGATIVE terminal" do
          %w(-1 -2 -3 -42 -123).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Integer.new(input)
          end
        end

        it "recognizes the DECIMAL_NEGATIVE terminal" do
          %w(-1. -3.1415 -.123).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Decimal.new(input)
          end
        end

        it "recognizes the DOUBLE_NEGATIVE terminal" do
          %w(-1e2 -3.1415e2 -.123e2).each do |input|
            parser(production).call(input).last.should eql RDF::Literal::Double.new(input)
          end
        end
      end
    end
  end
  
  # Individual terminal productions
  describe "individual terminal productions" do
    describe "when matching the [67] IRIref production rule" do
      with_production(:IRIref) do |production|
        it "recognizes the IRI_REF terminal" do
          %w(<> <foobar> <http://example.org/foobar>).each do |input|
            parser(production).call(input).last.should_not == false # TODO
          end
        end

        it "recognizes the PrefixedName nonterminal" do
          %w(: foo: :bar foo:bar).each do |input|
            parser(production).call(input).last.should_not == false # TODO
          end
        end
      end
    end

    describe "when matching the [68] PrefixedName production rule" do
      with_production(:PrefixedName) do |production|
        inputs = {
          :PNAME_LN => {
            ":bar"    => RDF::URI("http://example.com/bar"),
            "foo:bar" => RDF.bar
          },
          :PNAME_NS => {
            ":"    => RDF::URI("http://example.com/"),
            "foo:" => RDF.to_uri
          }
        }
        inputs.each do |terminal, examples|
          it "recognizes the #{terminal} terminal" do
            examples.each_pair do |input, result|
              p = parser(production, :prefixes => {nil => "http://example.com/", :foo => RDF.to_uri.to_s})
              p.call(input).last.should == result
            end
          end
        end
      end
    end

    describe "when matching the [69] BlankNode production rule" do
      with_production(:BlankNode) do |production|
        it "recognizes the BlankNode terminal" do
          if output = parser(production).call(%q(_:foobar))
            v = RDF::Query::Variable.new("foobar")
            v.distinguished = false
            output.last.should == v
            output.last.should_not be_distinguished
          end
        end

        it "recognizes the ANON terminal" do
          if output = parser(production).call(%q([]))
            output.last.should_not be_distinguished
          end
        end
      end
    end

    # NOTE: production rules [70..100] are internal to the lexer
  end

  def parser(production = nil, options = {})
    Proc.new do |query|
      parser = SPARQL::Grammar::Parser.new(query, {:resolve_uris => true}.merge(options))
      production ? parser.parse(production) : parser
    end
  end
end
