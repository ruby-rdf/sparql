#
# Shared Examples
#

#	FunctionCall
shared_examples "FunctionCall" do
  context "FunctionCall nonterminal" do
    {
      "<foo>('bar')" => [
        %q(<foo>("bar")), SPARQL::Algebra::Expression[:function_call, RDF::URI("foo"), RDF::Literal("bar")]
      ],
      "<foo>()" => [
        %q(<foo>()), SPARQL::Algebra::Expression[:function_call, RDF::URI("foo"), RDF["nil"]]
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end
end

#	Var
shared_examples "Var" do
  context "Var" do
    it "recognizes Var1" do |example|
      expect("?foo").to generate(RDF::Query::Variable.new(:foo), example.metadata)
    end
    it "recognizes Var2" do |example|
      expect("$foo").to generate(RDF::Query::Variable.new(:foo), example.metadata)
    end
  end
end

#	VarOrTerm
shared_examples "VarOrTerm" do
  include_examples "Var"
  include_examples "iri"
  include_examples "RDFLiteral"
  include_examples "NumericLiteral"
  include_examples "BooleanLiteral"
  include_examples "BlankNode"
  include_examples "NIL"
  #include_examples "TripleTerm"
end

# Expression
shared_examples "Expression" do
  context "Expression" do
    include_examples "ConditionalOrExpression"
  end
end

#    ConditionalOrExpression
shared_examples "ConditionalOrExpression" do
  context "ConditionalOrExpression" do
    {
      %q(1 || 2)      => SPARQL::Algebra::Expression[:"||", RDF::Literal(1), RDF::Literal(2)],
      %q(1 || 2 && 3) => SPARQL::Algebra::Expression[:"||", RDF::Literal(1), [:"&&", RDF::Literal(2), RDF::Literal(3)]],
      %q(1 && 2 || 3) => SPARQL::Algebra::Expression[:"||", [:"&&", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)],
      %q(1 || 2 || 3) => SPARQL::Algebra::Expression[:"||", [:"||", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
    include_examples "ConditionalAndExpression"
  end
end

#    ConditionalAndExpression
shared_examples "ConditionalAndExpression" do
  context "ConditionalAndExpression" do
    {
      %q(1 && 2)      => SPARQL::Algebra::Expression[:"&&", RDF::Literal(1), RDF::Literal(2)],
      %q(1 && 2 = 3)  => SPARQL::Algebra::Expression[:"&&", RDF::Literal(1), [:"=", RDF::Literal(2), RDF::Literal(3)]],
      %q(1 && 2 && 3) => SPARQL::Algebra::Expression[:"&&", [:"&&", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
    include_examples "ValueLogical"
  end
end

#    ValueLogical
shared_examples "ValueLogical" do
  context "ValueLogical" do
    include_examples "RelationalExpression"
  end
end

# RelationalExpression
shared_examples "RelationalExpression" do
  context "RelationalExpression" do
    {
      %q(1 = 2)          => SPARQL::Algebra::Expression[:"=", RDF::Literal(1), RDF::Literal(2)],
      %q(1 != 2)         => SPARQL::Algebra::Expression[:"!=", RDF::Literal(1), RDF::Literal(2)],
      %q(1 < 2)          => SPARQL::Algebra::Expression[:"<", RDF::Literal(1), RDF::Literal(2)],
      %q(1 > 2)          => SPARQL::Algebra::Expression[:">", RDF::Literal(1), RDF::Literal(2)],
      %q(1 <= 2)         => SPARQL::Algebra::Expression[:"<=", RDF::Literal(1), RDF::Literal(2)],
      %q(1 >= 2)         => SPARQL::Algebra::Expression[:">=", RDF::Literal(1), RDF::Literal(2)],
      %q(1 + 2 = 3)      => SPARQL::Algebra::Expression[:"=", [:"+", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)],
      %q(2 IN (1, 2, 3)) => SPARQL::Algebra::Expression[:in, RDF::Literal(2), RDF::Literal(1), RDF::Literal(2), RDF::Literal(3)],
      %q(2 IN (1))       => SPARQL::Algebra::Expression[:in, RDF::Literal(2), RDF::Literal(1)],
      %q(2 NOT IN ())    => SPARQL::Algebra::Expression[:notin, RDF::Literal(2)],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "NumericExpression"
  end
end

#    NumericExpression
shared_examples "NumericExpression" do
  context "NumericExpression" do
    include_examples "AdditiveExpression"
  end
end

#    AdditiveExpression
shared_examples "AdditiveExpression" do
  context "AdditiveExpression" do
    {
      %q(1 + 2)           => SPARQL::Algebra::Expression[:"+", RDF::Literal(1), RDF::Literal(2)],
      %q(1 - 2)           => SPARQL::Algebra::Expression[:"-", RDF::Literal(1), RDF::Literal(2)],
      %q(3+4)             => SPARQL::Algebra::Expression[:"+", RDF::Literal(3), RDF::Literal(4)],
      %q("1" + "2" - "3") => SPARQL::Algebra::Expression[:"-", [:"+", RDF::Literal("1"), RDF::Literal("2")], RDF::Literal("3")],
      %q("1" - "2" + "3") => SPARQL::Algebra::Expression[:"+", [:"-", RDF::Literal("1"), RDF::Literal("2")], RDF::Literal("3")],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "MultiplicativeExpression"
  end
end

#    MultiplicativeExpression
shared_examples "MultiplicativeExpression" do
  context "MultiplicativeExpression" do
    {
      %q(1 * 2)           => SPARQL::Algebra::Expression[:"*", RDF::Literal(1), RDF::Literal(2)],
      %q(1 / 2)           => SPARQL::Algebra::Expression[:"/", RDF::Literal(1), RDF::Literal(2)],
      %q(3*4)             => SPARQL::Algebra::Expression[:"*", RDF::Literal(3), RDF::Literal(4)],
      %q("1" * "2" * "3") => SPARQL::Algebra::Expression[:"*", [:"*", RDF::Literal("1"), RDF::Literal("2")], RDF::Literal("3")],
      %q("1" * "2" / "3") => SPARQL::Algebra::Expression[:"/", [:"*", RDF::Literal("1"), RDF::Literal("2")], RDF::Literal("3")],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "UnaryExpression"
  end
end

# UnaryExpression
shared_examples "UnaryExpression" do
  context "UnaryExpression" do
    {
      %q(! "foo") => SPARQL::Algebra::Expression[:not, RDF::Literal("foo")],
      %q(+ 1)     => RDF::Literal(1),
      %q(- 1)     => -RDF::Literal(1),
      %q(+ "foo") => RDF::Literal("foo"),
      %q(- "foo") => SPARQL::Algebra::Expression[:"-", RDF::Literal("foo")],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "PrimaryExpression"
  end
end

#    PrimaryExpression
shared_examples "PrimaryExpression" do
  context "PrimaryExpression" do
    include_examples "BrackettedExpression"
    include_examples "BuiltInCall"
    include_examples "iriOrFunction"
    include_examples "RDFLiteral"
    include_examples "NumericLiteral"
    include_examples "BooleanLiteral"
    include_examples "Var"
    #include_examples "ExprTripleTerm"
  end
end

#    BrackettedExpression
shared_examples "BrackettedExpression" do
  context "BrackettedExpression" do
    {
      %q(("foo")) => RDF::Literal("foo"),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end
end

# BuiltInCall
shared_examples "BuiltInCall" do
  context "BuiltInCall" do
    {
      %q(BOUND (?foo))               => SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("foo")],
      %q(BNODE (?s2))                => SPARQL::Algebra::Expression[:bnode, RDF::Query::Variable.new("s2")],
      %q(BNODE ())                   => SPARQL::Algebra::Expression[:bnode],
      %q(CONCAT (?str1, ?str2))      => SPARQL::Algebra::Expression[:concat, RDF::Query::Variable.new("str1"), RDF::Query::Variable.new("str2")],
      %q(DATATYPE ("foo"))           => SPARQL::Algebra::Expression[:datatype, RDF::Literal("foo")],
      %q(isBLANK ("foo"))            => SPARQL::Algebra::Expression[:isblank, RDF::Literal("foo")],
      %q(isIRI ("foo"))              => SPARQL::Algebra::Expression[:isiri, RDF::Literal("foo")],
      %q(isLITERAL ("foo"))          => SPARQL::Algebra::Expression[:isliteral, RDF::Literal("foo")],
      %q(isURI ("foo"))              => SPARQL::Algebra::Expression[:isuri, RDF::Literal("foo")],
      %q(LANG ("foo"))               => SPARQL::Algebra::Expression[:lang, RDF::Literal("foo")],
      %q(LANGMATCHES ("foo", "bar")) => SPARQL::Algebra::Expression[:langmatches, RDF::Literal("foo"), RDF::Literal("bar")],
      %q(sameTerm ("foo", "bar"))    => SPARQL::Algebra::Expression[:sameterm, RDF::Literal("foo"), RDF::Literal("bar")],
      %q(STR ("foo"))                => SPARQL::Algebra::Expression[:str, RDF::Literal("foo")],
      %q(SUBSTR(?str,1,2))           => SPARQL::Algebra::Expression[:substr, RDF::Query::Variable.new("str"), RDF::Literal(1), RDF::Literal(2)],
      %q(EXISTS {?s ?p ?o})          => %q((exists (bgp (triple ?s ?p ?o)))),
      %q(NOT EXISTS {?s ?p ?o})      => %q((notexists (bgp (triple ?s ?p ?o)))),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "Aggregate"
    include_examples "RegexExpression"
  end
end

#    RegexExpression
shared_examples "RegexExpression" do |**options|
  context "RegexExpression" do
    {
      %q(REGEX ("foo"))        => EBNF::LL1::Parser::Error,
      %q(REGEX ("foo", "bar")) => %q((regex "foo" "bar")),
      %q(REGEX ("foo", "bar", "i")) => %q((regex "foo" "bar" "i")),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false).merge(options))
      end
    end
  end
end

# BooleanLiteral
shared_examples "BooleanLiteral" do
  context "BooleanLiteral" do
    {
      "true"  => RDF::Literal(true),
      "false" => RDF::Literal(false),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end
end

# Aggregate
shared_examples "Aggregate" do
  context "Aggregate" do
    {
      %q(COUNT(*)) => %q((count)),
      %q(COUNT(?o)) => %q((count ?o)),
      %q(SUM(?o)) => %q((sum ?o)),
      %q(MIN(?value)) => %q((min ?value)),
      %q(MAX(?value)) => %q((max ?value)),
      %q(AVG(?o)) => %q((avg ?o)),
      %q(SAMPLE(?o)) => %q((sample ?o)),
      %q(GROUP_CONCAT(?o)) => %q((group_concat ?o)),
      %q(GROUP_CONCAT(?o;SEPARATOR=":")) => %q((group_concat (separator ":") ?o)),

      %q(COUNT(DISTINCT *)) => %q((count distinct)),
      %q(COUNT(DISTINCT ?o)) => %q((count distinct ?o)),
      %q(SUM(DISTINCT ?o)) => %q((sum distinct ?o)),
      %q(MIN(DISTINCT ?value)) => %q((min distinct ?value)),
      %q(MAX(DISTINCT ?value)) => %q((max distinct ?value)),
      %q(AVG(DISTINCT ?o)) => %q((avg distinct ?o)),
      %q(SAMPLE(DISTINCT ?o)) => %q((sample distinct ?o)),
      %q(GROUP_CONCAT(DISTINCT ?o)) => %q((group_concat distinct ?o)),
      %q(GROUP_CONCAT(DISTINCT ?o;SEPARATOR=":")) => %q((group_concat distinct (separator ":") ?o)),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata)
      end
    end
  end
end

#    iriOrFunction
shared_examples "iriOrFunction" do
  context "iriOrFunction" do
    include_examples "iri"
    include_examples "FunctionCall"
  end
end

# RDFLiteral
shared_examples "RDFLiteral" do
  context "RDFLiteral" do
    {
      %q("")            => RDF::Literal.new(""),
      %q('foobar')      => RDF::Literal('foobar'),
      %q("foobar")      => RDF::Literal('foobar'),
      %q('''foobar''')  => RDF::Literal('foobar'),
      %q("""foobar""")  => RDF::Literal('foobar'),
      %q(""@en)         => RDF::Literal.new("", language: :en),
      %q("foobar"@en-US)=> RDF::Literal.new("foobar", language: :'en-us'),
      %q(""^^<http://www.w3.org/2001/XMLSchema#string>) => RDF::Literal.new("", datatype: RDF::XSD.string),
      %q("foobar"^^<http://www.w3.org/2001/XMLSchema#string>) => RDF::Literal.new("foobar", datatype: RDF::XSD.string),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end
end

# NumericLiteral
shared_examples "NumericLiteral" do
  context "NumericLiteral" do
    {
      #%q()        => EBNF::LL1::Parser::Error,
      %q(123)     => RDF::Literal::Integer.new(123),
      %q(+123)    => RDF::Literal::Integer.new(123),
      %q(-123)    => RDF::Literal::Integer.new(-123),
      %q(3.1415)  => RDF::Literal::Decimal.new("3.1415"),
      %q(+3.1415) => RDF::Literal::Decimal.new("3.1415"),
      %q(-3.1415) => RDF::Literal::Decimal.new("-3.1415"),
      %q(1e6)     => RDF::Literal::Double.new(1e6),
      %q(+1e6)    => RDF::Literal::Double.new(1e6),
      %q(-1e6)    => RDF::Literal::Double.new(-1e6),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    it "recognizes the INTEGER terminal" do |example|
      %w(1 2 3 42 123).each do |input|
        expect(input).to generate(RDF::Literal::Integer.new(input), example.metadata)
      end
    end

    it "recognizes the DECIMAL terminal" do |example|
      %w(1.0 3.1415 .123).each do |input|
        expect(input).to generate(RDF::Literal::Decimal.new(input), example.metadata)
      end
    end

    it "recognizes the DOUBLE terminal" do |example|
      %w(1e2 3.1415e2 .123e2).each do |input|
        expect(input).to generate(RDF::Literal::Double.new(input), example.metadata)
      end
    end
    it "recognizes the INTEGER_POSITIVE terminal" do |example|
      %w(+1 +2 +3 +42 +123).each do |input|
        expect(input).to generate(RDF::Literal::Integer.new(input), example.metadata)
      end
    end

    it "recognizes the DECIMAL_POSITIVE terminal" do |example|
      %w(+1.0 +3.1415 +.123).each do |input|
        expect(input).to generate(RDF::Literal::Decimal.new(input), example.metadata)
      end
    end

    it "recognizes the DOUBLE_POSITIVE terminal" do |example|
      %w(+1e2 +3.1415e2 +.123e2).each do |input|
        expect(input).to generate(RDF::Literal::Double.new(input), example.metadata)
      end
    end
    it "recognizes the INTEGER_NEGATIVE terminal" do |example|
      %w(-1 -2 -3 -42 -123).each do |input|
        expect(input).to generate(RDF::Literal::Integer.new(input), example.metadata)
      end
    end

    it "recognizes the DECIMAL_NEGATIVE terminal" do |example|
      %w(-1.0 -3.1415 -.123).each do |input|
        expect(input).to generate(RDF::Literal::Decimal.new(input), example.metadata)
      end
    end

    it "recognizes the DOUBLE_NEGATIVE terminal" do |example|
      %w(-1e2 -3.1415e2 -.123e2).each do |input|
        expect(input).to generate(RDF::Literal::Double.new(input), example.metadata)
      end
    end
  end
end

# iri
shared_examples "iri" do
  context "iri" do
    {
      %q(<http://example.org/>) => RDF::URI('http://example.org/')
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    it "recognizes the IRIREF terminal" do |example|
      %w(<> <foobar> <http://example.org/foobar>).each do |input|
        expect(input).to generate(RDF::URI(input[1..-2]), example.metadata)
      end
    end

    #it "recognizes the PrefixedName nonterminal" do |example|
    #  %w(: foo: :bar foo:bar).each do |input|
    #    expect(parser(example.metadata[:production]).call(input)).not_to be_falsey # TODO
    #  end
    #end
  end
end

# BlankNode
shared_examples "BlankNode" do
  context "BlankNode" do
    it %q(_:foobar) do |example|
      expect(%q(_:foobar)).to generate(SPARQL::Grammar::Parser.variable("foobar", false), example.metadata)
    end
    specify {|example| expect(parser(example.metadata[:production]).call(%q([]))).not_to be_distinguished}
  end
end

# NIL
shared_examples "NIL" do
  context "NIL" do
    specify {|example| expect(parser(example.metadata[:production]).call(%q(()))).to eq RDF.nil}
  end
end

shared_examples "BGP Patterns" do |wrapper|
  context "BGP Patterns", all_vars: false do
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
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal("foobar", language: :en)]
      end,
      %q(<a><b>"foobar"^^<c>) => RDF::Query.new do
        pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal("foobar", datatype: RDF::URI("http://example.org/c"))]
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
    }.each do |input, output|
      it input do |example|
        expect(wrapper % input).to generate(output,
          logger: RDF::Spec.logger.tap {|l| l.level = Logger::DEBUG},
          prefixes: {
            nil => "http://example.com/",
            rdf: RDF.to_uri.to_s
          },
          base_uri: RDF::URI("http://example.org/"),
          anon_base: "b0",
          **example.metadata)
      end
    end
  end
end
