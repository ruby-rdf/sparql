$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'

class SPARQL::Grammar::Parser
  # Class method version to aid in specs
  def self.variable(id, distinguished = true)
    SPARQL::Grammar::Parser.new.send(:variable, id, distinguished)
  end
end

# [70]	FunctionCall
shared_examples "FunctionCall" do
  context "FunctionCall nonterminal" do
    {
      "<foo>('bar')" => [
        %q(<foo>("bar")), [RDF::URI("foo"), RDF::Literal("bar")]
      ],
      "<foo>()" => [
        %q(<foo>()), [RDF::URI("foo"), RDF["nil"]]
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end
end

# [108]	Var
shared_examples "Var" do
  context "Var" do
    it "recognizes Var1" do |example|
      expect("?foo").to generate(RDF::Query::Variable.new(:foo), example.metadata.merge(last: true))
    end
    it "recognizes Var2" do |example|
      expect("$foo").to generate(RDF::Query::Variable.new(:foo), example.metadata.merge(last: true))
    end
  end
end

# [109] GraphTerm
shared_examples "GraphTerm" do
  context "GraphTerm" do
    include_examples "iri"
    include_examples "RDFLiteral"
    include_examples "NumericLiteral"
    include_examples "BooleanLiteral"
    include_examples "BlankNode"
    include_examples "NIL"
  end
end

# [110]    Expression
shared_examples "Expression" do
  context "Expression" do
    include_examples "ConditionalOrExpression"
  end
end

# [111]    ConditionalOrExpression
shared_examples "ConditionalOrExpression" do
  context "ConditionalOrExpression" do
    {
      %q(1 || 2)      => SPARQL::Algebra::Expression[:"||", RDF::Literal(1), RDF::Literal(2)],
      %q(1 || 2 && 3) => SPARQL::Algebra::Expression[:"||", RDF::Literal(1), [:"&&", RDF::Literal(2), RDF::Literal(3)]],
      %q(1 && 2 || 3) => SPARQL::Algebra::Expression[:"||", [:"&&", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)],
      %q(1 || 2 || 3) => SPARQL::Algebra::Expression[:"||", [:"||", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
    include_examples "ConditionalAndExpression"
  end
end

# [112]    ConditionalAndExpression
shared_examples "ConditionalAndExpression" do
  context "ConditionalAndExpression" do
    {
      %q(1 && 2)      => SPARQL::Algebra::Expression[:"&&", RDF::Literal(1), RDF::Literal(2)],
      %q(1 && 2 = 3)  => SPARQL::Algebra::Expression[:"&&", RDF::Literal(1), [:"=", RDF::Literal(2), RDF::Literal(3)]],
      %q(1 && 2 && 3) => SPARQL::Algebra::Expression[:"&&", [:"&&", RDF::Literal(1), RDF::Literal(2)], RDF::Literal(3)],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
    include_examples "ValueLogical"
  end
end

# [113]    ValueLogical
shared_examples "ValueLogical" do
  context "ValueLogical" do
    include_examples "RelationalExpression"
  end
end

# [114] RelationalExpression
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
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end

    include_examples "NumericExpression"
  end
end

# [115]    NumericExpression
shared_examples "NumericExpression" do
  context "NumericExpression" do
    include_examples "AdditiveExpression"
  end
end

# [116]    AdditiveExpression
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
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end

    include_examples "MultiplicativeExpression"
  end
end

# [117]    MultiplicativeExpression
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
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end

    include_examples "UnaryExpression"
  end
end

# [118] UnaryExpression
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
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end

    include_examples "PrimaryExpression"
  end
end

# [119]    PrimaryExpression
shared_examples "PrimaryExpression" do
  context "PrimaryExpression" do
    include_examples "BrackettedExpression"
    include_examples "BuiltInCall"
    include_examples "iriOrFunction"
    include_examples "RDFLiteral"
    include_examples "NumericLiteral"
    include_examples "BooleanLiteral"
    include_examples "Var"
  end
end

# [120]    BrackettedExpression
shared_examples "BrackettedExpression" do
  context "BrackettedExpression" do
    {
      %q(("foo")) => [RDF::Literal("foo")],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, shift: true))
      end
    end
  end
end

# [121] BuiltInCall
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
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end

    include_examples "Aggregate"
    include_examples "RegexExpression"
  end
end

# [122]    RegexExpression
shared_examples "RegexExpression" do |**options|
  context "RegexExpression" do
    {
      %q(REGEX ("foo"))        => EBNF::LL1::Parser::Error,
      %q(REGEX ("foo", "bar")) => %q((regex "foo" "bar" "")),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true).merge(options))
      end
    end
  end
end

# [123] BooleanLiteral
shared_examples "BooleanLiteral" do
  context "BooleanLiteral" do
    {
      "true"  => RDF::Literal(true),
      "false" => RDF::Literal(false),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end
end

# [127] Aggregate
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
      %q(GROUP_CONCAT(DISTINCT ?o;SEPARATOR=":")) => %q((group_concat (separator ":") distinct ?o)),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(last: true))
      end
    end
  end
end

# [128]    iriOrFunction
shared_examples "iriOrFunction" do
  context "iriOrFunction" do
    include_examples "iri"
    include_examples "FunctionCall"
  end
end

# [129] RDFLiteral
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
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end
end

# [130] NumericLiteral
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
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end

    it "recognizes the INTEGER terminal" do |example|
      %w(1 2 3 42 123).each do |input|
        expect(input).to generate(RDF::Literal::Integer.new(input), example.metadata.merge(last: true))
      end
    end

    it "recognizes the DECIMAL terminal" do |example|
      %w(1.0 3.1415 .123).each do |input|
        expect(input).to generate(RDF::Literal::Decimal.new(input), example.metadata.merge(last: true))
      end
    end

    it "recognizes the DOUBLE terminal" do |example|
      %w(1e2 3.1415e2 .123e2).each do |input|
        expect(input).to generate(RDF::Literal::Double.new(input), example.metadata.merge(last: true))
      end
    end
    it "recognizes the INTEGER_POSITIVE terminal" do |example|
      %w(+1 +2 +3 +42 +123).each do |input|
        expect(input).to generate(RDF::Literal::Integer.new(input), example.metadata.merge(last: true))
      end
    end

    it "recognizes the DECIMAL_POSITIVE terminal" do |example|
      %w(+1.0 +3.1415 +.123).each do |input|
        expect(input).to generate(RDF::Literal::Decimal.new(input), example.metadata.merge(last: true))
      end
    end

    it "recognizes the DOUBLE_POSITIVE terminal" do |example|
      %w(+1e2 +3.1415e2 +.123e2).each do |input|
        expect(input).to generate(RDF::Literal::Double.new(input), example.metadata.merge(last: true))
      end
    end
    it "recognizes the INTEGER_NEGATIVE terminal" do |example|
      %w(-1 -2 -3 -42 -123).each do |input|
        expect(input).to generate(RDF::Literal::Integer.new(input), example.metadata.merge(last: true))
      end
    end

    it "recognizes the DECIMAL_NEGATIVE terminal" do |example|
      %w(-1.0 -3.1415 -.123).each do |input|
        expect(input).to generate(RDF::Literal::Decimal.new(input), example.metadata.merge(last: true))
      end
    end

    it "recognizes the DOUBLE_NEGATIVE terminal" do |example|
      %w(-1e2 -3.1415e2 -.123e2).each do |input|
        expect(input).to generate(RDF::Literal::Double.new(input), example.metadata.merge(last: true))
      end
    end
  end
end

# [136] iri
shared_examples "iri" do
  context "iri" do
    {
      %q(<http://example.org/>) => RDF::URI('http://example.org/')
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end

    it "recognizes the IRIREF terminal" do |example|
      %w(<> <foobar> <http://example.org/foobar>).each do |input|
        expect(input).to generate(RDF::URI(input[1..-2]), example.metadata.merge(last: true))
      end
    end

    it "recognizes the PrefixedName nonterminal" do |example|
      %w(: foo: :bar foo:bar).each do |input|
        expect(parser(example.metadata[:production]).call(input).last).not_to be_falsey # TODO
      end
    end
  end
end

# [138] BlankNode
shared_examples "BlankNode" do
  context "BlankNode" do
    it %q(_:foobar) do |example|
      expect(%q(_:foobar)).to generate(SPARQL::Grammar::Parser.variable("foobar", false), example.metadata.merge(last: true))
    end
    specify {|example| expect(parser(example.metadata[:production]).call(%q([])).last).not_to be_distinguished}
  end
end

# [161] NIL
shared_examples "NIL" do
  context "NIL" do
    specify {|example| expect(parser(example.metadata[:production]).call(%q(())).last).to eq RDF.nil}
  end
end

shared_examples "BGP Patterns" do |wrapper|
  context "BGP Patterns" do
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
        expect(wrapper % input).to generate(output, example.metadata.merge(
          prefixes: {
            nil => "http://example.com/",
            rdf: RDF.to_uri.to_s
          },
          base_uri: RDF::URI("http://example.org/"),
          anon_base: "b0"))
      end
    end
  end
end

describe SPARQL::Grammar::Parser do
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}

  describe "#initialize" do
    it "accepts a string query" do |example|
      expect {
        described_class.new("foo") {
          raise "huh" unless input == "foo"
          }
        }.not_to raise_error
    end

    it "accepts a StringIO query" do |example|
      expect {
        described_class.new(StringIO.new("foo")) {
          raise "huh" unless input == "foo"
          }
        }.not_to raise_error
    end
  end

  describe "when matching the [1] QueryUnit production rule", production: :QueryUnit do
    {
      empty: ["", nil],
      select: [
        %q(SELECT * FROM <a> WHERE {?a ?b ?c}),
        %q((dataset (<a>) (bgp (triple ?a ?b ?c))))
      ],
      construct: [
        %q(CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}),
        %q((construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
      describe: [
        %q(DESCRIBE * FROM <a> WHERE {?a ?b ?c}),
        %q((describe () (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      ask: [
        "ASK WHERE {GRAPH <a> {?a ?b ?c}}",
        %q((ask (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [2] Query production rule", production: :Query do
    {
      "base" => [
        "BASE <foo/> SELECT * WHERE { <a> <b> <c> }",
        %q((base <foo/> (bgp (triple <a> <b> <c>))))
      ],
      "prefix(1)" => [
        "PREFIX : <http://example.com/> SELECT * WHERE { :a :b :c }",
        %q((prefix ((: <http://example.com/>)) (bgp (triple :a :b :c))))
      ],
      "prefix(2)" => [
        "PREFIX : <foo#> PREFIX bar: <bar#> SELECT * WHERE { :a :b bar:c }",
          %q((prefix ((: <foo#>) (bar: <bar#>)) (bgp (triple :a :b bar:c))))
      ],
      "base+prefix" => [
        "BASE <http://baz/> PREFIX : <http://foo#> PREFIX bar: <http://bar#> SELECT * WHERE { <a> :b bar:c }",
        %q((base <http://baz/> (prefix ((: <http://foo#>) (bar: <http://bar#>)) (bgp (triple <a> :b bar:c)))))
      ],
      "from" => [
        "SELECT * FROM <a> WHERE {?a ?b ?c}",
        %q((dataset (<a>) (bgp (triple ?a ?b ?c))))
      ],
      "from named" => [
        "SELECT * FROM NAMED <a> WHERE {?a ?b ?c}",
        %q((dataset ((named <a>)) (bgp (triple ?a ?b ?c))))
      ],
      "graph" => [
        "SELECT * WHERE {GRAPH <a> {?a ?b ?c}}",
        %q((graph <a> (bgp (triple ?a ?b ?c))))
      ],
      "optional" => [
        "SELECT * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}",
        %q((leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "join" => [
        "SELECT * WHERE {?a ?b ?c {?d ?e ?f}}",
        %q((join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "union" => [
        "SELECT * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}",
        %q((union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "Var+" => [
        "SELECT ?a ?b WHERE {?a ?b ?c}",
        %q((project (?a ?b) (bgp (triple ?a ?b ?c))))
      ],
      "distinct(1)" => [
        "SELECT DISTINCT * WHERE {?a ?b ?c}",
        %q((distinct (bgp (triple ?a ?b ?c))))
      ],
      "distinct(2)" => [
        "SELECT DISTINCT ?a ?b WHERE {?a ?b ?c}",
        %q((distinct (project (?a ?b) (bgp (triple ?a ?b ?c)))))
      ],
      "reduced(1)" => [
        "SELECT REDUCED * WHERE {?a ?b ?c}",
        %q((reduced (bgp (triple ?a ?b ?c))))
      ],
      "reduced(2)" => [
        "SELECT REDUCED ?a ?b WHERE {?a ?b ?c}",
        %q((reduced (project (?a ?b) (bgp (triple ?a ?b ?c)))))
      ],
      "filter(1)" => [
        "SELECT * WHERE {?a ?b ?c FILTER (?a)}", %q((filter ?a (bgp (triple ?a ?b ?c))))
      ],
      "filter(2)" => [
        "SELECT * WHERE {FILTER (?a) ?a ?b ?c}", %q((filter ?a (bgp (triple ?a ?b ?c))))
      ],
      "filter(3)" => [
        "SELECT * WHERE { FILTER (?o>5) . ?s ?p ?o }", %q((filter (> ?o 5) (bgp (triple ?s ?p ?o))))
      ],
      "construct from" => [
        "CONSTRUCT {?a ?b ?c} FROM <a> WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      "construct from named" => [
        "CONSTRUCT {?a ?b ?c} FROM NAMED <a> WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (dataset ((named <a>)) (bgp (triple ?a ?b ?c)))))
      ],
      "construct graph" => [
        "CONSTRUCT {?a ?b ?c} WHERE {GRAPH <a> {?a ?b ?c}}", %q((construct ((triple ?a ?b ?c)) (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
      "construct optional" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct join" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct union" => [
        "CONSTRUCT {?a ?b ?c} WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct filter" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}", %q((construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
      "describe" => [
        "DESCRIBE * FROM <a> WHERE {?a ?b ?c}", %q((describe () (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      "ask" => [
        "ASK WHERE {GRAPH <a> {?a ?b ?c}}", %q((ask (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
      "count" => [
        %q(SELECT (COUNT(?O) AS ?C) WHERE {?S ?P ?O}), %q((project (?C) (extend ((?C ??.0)) (group () ((??.0 (count ?O))) (bgp (triple ?S ?P ?O))))))
      ],
      "illegal bind variable" => [
        %q(SELECT * WHERE { ?s ?p ?o . BIND (?p AS ?o) }),
        EBNF::LL1::Parser::Error
      ],
      "illegal bind variable (graph name)" => [
        %q(SELECT * WHERE { GRAPH ?g {?s ?p ?o} . BIND (?p AS ?g) }),
        EBNF::LL1::Parser::Error
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "BGP Patterns", "SELECT * WHERE {%s}"
  end

  describe "when matching the [4] Prologue production rule", production: :Prologue do
    it "sets base_uri to <http://example.org> given 'BASE <http://example.org/>'" do |example|
      p = parser(nil, resolve_iris: true).call(%q(BASE <http://example.org/>))
      p.parse(example.metadata[:production])
      expect(p.send(:base_uri)).to eq RDF::URI('http://example.org/')
    end

    it "sets prefix : to 'foobar' given 'PREFIX : <foobar>'" do |example|
      p = parser(nil, resolve_iris: true).call(%q(PREFIX : <foobar>))
      p.parse(example.metadata[:production])
      expect(p.send(:prefix, nil)).to eq 'foobar'
      expect(p.send(:prefixes)[nil]).to eq 'foobar'
    end

    it "sets prefix foo: to 'bar' given 'PREFIX foo: <bar>'" do |example|
      p = parser(nil, resolve_iris: true).call(%q(PREFIX foo: <bar>))
      p.parse(example.metadata[:production])
      expect(p.send(:prefix, :foo)).to eq 'bar'
      expect(p.send(:prefix, "foo")).to eq 'bar'
      expect(p.send(:prefixes)[:foo]).to eq 'bar'
    end

    {
      "base" => [
        %q(BASE <http://example.org/>), [:BaseDecl, RDF::URI("http://example.org/")]
      ],
      "empty prefix" => [
        %q(PREFIX : <foobar>),
        [:PrefixDecl, SPARQL::Algebra::Operator::Prefix.new([[:":", RDF::URI("foobar")]], [])]
      ],
      "prefix" => [
        %q(PREFIX foo: <bar>),
        [:PrefixDecl, SPARQL::Algebra::Operator::Prefix.new([[:"foo:", RDF::URI("bar")]], [])]
      ],
      "both prefixes" => [
        %q(PREFIX : <foobar> PREFIX foo: <bar>),
        [:PrefixDecl,
          SPARQL::Algebra::Operator::Prefix.new([[:":", RDF::URI("foobar")]], []),
          SPARQL::Algebra::Operator::Prefix.new([[:"foo:", RDF::URI("bar")]], [])
        ]
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [7] SelectQuery production rule", production: :SelectQuery do
    {
      "from" => [
        "SELECT * FROM <a> WHERE {?a ?b ?c}",
        %q((dataset (<a>) (bgp (triple ?a ?b ?c))))
      ],
      "from (lc)" => [
        "select * from <a> where {?a ?b ?c}",
        %q((dataset (<a>) (bgp (triple ?a ?b ?c))))
      ],
      "from named" => [
        "SELECT * FROM NAMED <a> WHERE {?a ?b ?c}",
        %q((dataset ((named <a>)) (bgp (triple ?a ?b ?c))))
      ],
      "graph" => [
        "SELECT * WHERE {GRAPH <a> {?a ?b ?c}}",
        %q((graph <a> (bgp (triple ?a ?b ?c))))
      ],
      "graph (var)" => [
        "SELECT * {GRAPH ?g { :x :b ?a . GRAPH ?g2 { :x :p ?x } }}",
        %q((graph ?g
            (join
              (bgp (triple <x> <b> ?a))
              (graph ?g2
                (bgp (triple <x> <p> ?x))))))
      ],
      "optional" => [
        "SELECT * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}",
        %q((leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "join" => [
        "SELECT * WHERE {?a ?b ?c {?d ?e ?f}}",
        %q((join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "union" => [
        "SELECT * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}",
        %q((union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "Var+" => [
        "SELECT ?a ?b WHERE {?a ?b ?c}",
        %q((project (?a ?b) (bgp (triple ?a ?b ?c))))
      ],
      "Expression" => [
        "SELECT (?c+10 AS ?z) WHERE {?a ?b ?c}",
        %q((project (?z) (extend ((?z (+ ?c 10))) (bgp (triple ?a ?b ?c)))))
      ],
      "distinct(1)" => [
        "SELECT DISTINCT * WHERE {?a ?b ?c}",
        %q((distinct (bgp (triple ?a ?b ?c))))
      ],
      "distinct(2)" => [
        "SELECT DISTINCT ?a ?b WHERE {?a ?b ?c}",
        %q((distinct (project (?a ?b) (bgp (triple ?a ?b ?c)))))
      ],
      "reduced(1)" => [
        "SELECT REDUCED * WHERE {?a ?b ?c}",
        %q((reduced (bgp (triple ?a ?b ?c))))
      ],
      "reduced(2)" => [
        "SELECT REDUCED ?a ?b WHERE {?a ?b ?c}",
        %q((reduced (project (?a ?b) (bgp (triple ?a ?b ?c)))))
      ],
      "filter(1)" => [
        "SELECT * WHERE {?a ?b ?c FILTER (?a)}", %q((filter ?a (bgp (triple ?a ?b ?c))))
      ],
      "filter(2)" => [
        "SELECT * WHERE {FILTER (?a) ?a ?b ?c}", %q((filter ?a (bgp (triple ?a ?b ?c))))
      ],
      "filter(3)" => [
        "SELECT * WHERE { FILTER (?o>5) . ?s ?p ?o }", %q((filter (> ?o 5) (bgp (triple ?s ?p ?o))))
      ],
      "bind(1)" => [
        "SELECT ?z {?s ?p ?o . BIND(?o+10 AS ?z)}",
        %q(
        (project (?z)
          (extend ((?z (+ ?o 10)))
            (bgp (triple ?s ?p ?o))))
        )
      ],
      "bind(2)" => [
        "SELECT ?o ?z ?z2 {?s ?p ?o . BIND(?o+10 AS ?z) BIND(?o+100 AS ?z2)}",
        %q(
        (project (?o ?z ?z2)
          (extend ((?z (+ ?o 10)) (?z2 (+ ?o 100)))
            (bgp (triple ?s ?p ?o))))
        )
      ],
      "group(1)" => [
        "SELECT ?s {?s :p ?v .} GROUP BY ?s",
        %q(
        (project (?s)
          (group (?s)
            (bgp (triple ?s <p> ?v))))
        )
      ],
      #"group+expression" => [
      #  "SELECT ?w (SAMPLE(?v) AS ?S) {?s :p ?v . OPTIONAL { ?s :q ?w }} GROUP BY ?w",
      #  %q(
      #  (project (?w ?S)
      #    (extend ((?S ??.0))
      #      (group (?w) ((??.0 (sample ?v)))
      #        (leftjoin
      #          (bgp (triple ?s <p> ?v))
      #          (bgp (triple ?s <q> ?w))))))
      #  )
      #]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end

    include_examples "BGP Patterns", "SELECT * WHERE {%s}"
  end

  describe "when matching the [9] SelectClause production rule", production: :SelectClause do
    {
      "var" => [
        "SELECT ?a", %q((Var ?a))
      ],
      "var+var" => [
        "SELECT ?a ?b", %q((Var ?a ?b))
      ],
      "*" => [
        "SELECT *", %q((MultiplicativeExpression "*"))
      ],
      "Expression" => [
        "SELECT (?o+10 AS ?z)", %q((extend (?z (+ ?o 10))))
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the [10] ConstructQuery production rule", production: :ConstructQuery do
    {
      "construct from" => [
        "CONSTRUCT {?a ?b ?c} FROM <a> WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      "construct from named" => [
        "CONSTRUCT {?a ?b ?c} FROM NAMED <a> WHERE {?a ?b ?c}", %q((construct ((triple ?a ?b ?c)) (dataset ((named <a>)) (bgp (triple ?a ?b ?c)))))
      ],
      "construct graph" => [
        "CONSTRUCT {?a ?b ?c} WHERE {GRAPH <a> {?a ?b ?c}}", %q((construct ((triple ?a ?b ?c)) (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
      "construct optional" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct join" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct union" => [
        "CONSTRUCT {?a ?b ?c} WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((construct ((triple ?a ?b ?c)) (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct filter" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}", %q((construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [11] DescribeQuery production rule", production: :DescribeQuery do
    {
      "describe" => [
        "DESCRIBE * WHERE {?a ?b ?c}", %q((describe () (bgp (triple ?a ?b ?c))))
      ],
      "describe from" => [
        "DESCRIBE * FROM <a> WHERE {?a ?b ?c}", %q((describe () (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      "describe from named" => [
        "DESCRIBE * FROM NAMED <a> WHERE {?a ?b ?c}", %q((describe () (dataset ((named <a>)) (bgp (triple ?a ?b ?c)))))
      ],
      "describe graph" => [
        "DESCRIBE * WHERE {GRAPH <a> {?a ?b ?c}}", %q((describe () (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
      "describe optional" => [
        "DESCRIBE * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((describe () (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "describe join" => [
        "DESCRIBE * WHERE {?a ?b ?c {?d ?e ?f}}", %q((describe () (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "describe union" => [
        "DESCRIBE * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((describe () (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "describe filter" => [
        "DESCRIBE * WHERE {?a ?b ?c FILTER (?a)}", %q((describe () (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
      "no query" => [
        "DESCRIBE *", %q((describe () (bgp)))
      ],
      "no query var" => [
        "DESCRIBE ?a", %q((describe (?a) (bgp)))
      ],
      "no query from" => [
        "DESCRIBE * FROM <a>", %q((describe () (dataset (<a>) (bgp))))
      ],
      "iri" => [
        "DESCRIBE <a> WHERE {?a ?b ?c}", %q((describe (<a>) (bgp (triple ?a ?b ?c))))
      ],
      "var+iri" => [
        "DESCRIBE ?a <a> WHERE {?a ?b ?c}", %q((describe (?a <a>) (bgp (triple ?a ?b ?c))))
      ],
      "var+var" => [
        "DESCRIBE ?a ?b WHERE {?a ?b ?c}", %q((describe (?a ?b) (bgp (triple ?a ?b ?c))))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [12] AskQuery production rule", production: :AskQuery do
    {
      "ask" => [
        "ASK WHERE {?a ?b ?c}", %q((ask (bgp (triple ?a ?b ?c))))
      ],
      "ask from" => [
        "ASK FROM <a> WHERE {?a ?b ?c}", %q((ask (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      "ask from named" => [
        "ASK FROM NAMED <a> WHERE {?a ?b ?c}", %q((ask (dataset ((named <a>)) (bgp (triple ?a ?b ?c)))))
      ],
      "ask graph" => [
        "ASK WHERE {GRAPH <a> {?a ?b ?c}}", %q((ask (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
      "ask optional" => [
        "ASK WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((ask (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "ask join" => [
        "ASK WHERE {?a ?b ?c {?d ?e ?f}}", %q((ask (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "ask union" => [
        "ASK WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((ask (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "ask filter" => [
        "ASK WHERE {?a ?b ?c FILTER (?a)}", %q((ask (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [13] DatasetClause production rule", production: :DatasetClause do
    {
      "from" => [
        %q(FROM <http://example.org/foaf/aliceFoaf>),
        [:dataset, RDF::URI("http://example.org/foaf/aliceFoaf")]
      ],
      "from named" => [
        %q(FROM NAMED <http://example.org/foaf/aliceFoaf>),
        [:dataset, [:named, RDF::URI("http://example.org/foaf/aliceFoaf")]]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  # No specs for the following, as nothing is produced in SSE.
  #   [14] DefaultGraphClause
  #   [15] NamedGraphClause
  #   [16] SourceSelector
  describe "when matching the [17] WhereClause production rule", production: :WhereClause do
    {
      "where" => [
        "WHERE {?a ?b ?c}", %q((bgp (triple ?a ?b ?c)))
      ],
      "where graph" => [
        "WHERE {GRAPH <a> {?a ?b ?c}}", %q((graph <a> (bgp (triple ?a ?b ?c))))
      ],
      "where optional" => [
        "WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q((leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "where join" => [
        "WHERE {?a ?b ?c {?d ?e ?f}}", %q((join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "where union" => [
        "WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q((union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))
      ],
      "where filter" => [
        "WHERE {?a ?b ?c FILTER (?a)}", %q((filter ?a (bgp (triple ?a ?b ?c))))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "BGP Patterns", "WHERE {%s}"
  end

  describe "when matching the [18] SolutionModifier production rule", production: :SolutionModifier do
    {
      "group" => [
        "GROUP BY ?s", %q((group (?s)))
      ],
      "limit" => [
        "LIMIT 1", [:slice, :_, RDF::Literal(1)]
      ],
      "offset" => [
        "OFFSET 1", [:slice, RDF::Literal(1), :_]
      ],
      "limit+offset" => [
        "LIMIT 1 OFFSET 2", [:slice, RDF::Literal(2), RDF::Literal(1)]
      ],
      "offset+limit" => [
        "OFFSET 2 LIMIT 1", [:slice, RDF::Literal(2), RDF::Literal(1)]
      ],
      "order asc" => [
        "ORDER BY ASC (1)", [:order, [SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1))]]
      ],
      "order desc" => [
        "ORDER BY DESC (?a)", [:order, [SPARQL::Algebra::Operator::Desc.new(RDF::Query::Variable.new("a"))]]
      ],
      "order var" => [
        "ORDER BY ?a ?b ?c", [:order, [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), RDF::Query::Variable.new("c")]]
      ],
      "order var+asc+isURI" => [
        "ORDER BY ?a ASC (1) isURI(<b>)", [:order, [RDF::Query::Variable.new("a"), SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1)), SPARQL::Algebra::Operator::IsURI.new(RDF::URI("b"))]]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [19] GroupClause production rule", production: :GroupClause do
    {
      "Var" => [
        "GROUP BY ?s", %q((group (?s)))
      ],
      "Var+Var" => [
        "GROUP BY ?s ?w", %q((group (?s ?w)))
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [20] GroupCondition production rule", production: :GroupCondition do
    {
      "BuiltInCall" => [
        %q(STR ("foo")), %q((GroupCondition (str "foo")))
      ],
      "FunctionCall" => [
        "<foo>('bar')", %q((GroupCondition (<foo> "bar")))
      ],
      "Expression" => [
        %q((COALESCE(?w, "1605-11-05"^^xsd:date))),
        %q((GroupCondition (coalesce ?w "1605-11-05"^^xsd:date)))
      ],
      "Expression+VAR" => [
        %q((COALESCE(?w, "1605-11-05"^^xsd:date) AS ?X)),
        %q((GroupCondition (?X (coalesce ?w "1605-11-05"^^xsd:date))))
      ],
      "Var" => [
        "?s", %q((GroupCondition ?s))
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [23] OrderClause production rule", production: :OrderClause do
    {
      "order asc" => [
        "ORDER BY ASC (1)", [:order, [SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1))]]
      ],
      "order desc" => [
        "ORDER BY DESC (?a)", [:order, [SPARQL::Algebra::Operator::Desc.new(RDF::Query::Variable.new("a"))]]
      ],
      "order var" => [
        "ORDER BY ?a ?b ?c", [:order, [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), RDF::Query::Variable.new("c")]]
      ],
      "order var+asc+isURI" => [
        "ORDER BY ?a ASC (1) isURI(<b>)", [:order, [RDF::Query::Variable.new("a"), SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1)), SPARQL::Algebra::Operator::IsURI.new(RDF::URI("b"))]]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [24] OrderCondition production rule", production: :OrderCondition do
    {
      "asc" => [
        "ASC (1)", [:OrderCondition, SPARQL::Algebra::Expression[:asc, RDF::Literal(1)]]
      ],
      "desc" => [
        "DESC (?a)", [:OrderCondition, SPARQL::Algebra::Expression[:desc, RDF::Query::Variable.new("a")]]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
    include_examples "FunctionCall"
    include_examples "BrackettedExpression"
    include_examples "BuiltInCall"
    include_examples "Var"
  end

  describe "when matching the [25] LimitOffsetClauses production rule", production: :LimitOffsetClauses do
    {
      "limit" => [
        "LIMIT 1", [:slice, :_, RDF::Literal(1)]
      ],
      "offset" => [
        "OFFSET 1", [:slice, RDF::Literal(1), :_]
      ],
      "limit+offset" => [
        "LIMIT 1 OFFSET 2", [:slice, RDF::Literal(2), RDF::Literal(1)]
      ],
      "offset+limit" => [
        "OFFSET 2 LIMIT 1", [:slice, RDF::Literal(2), RDF::Literal(1)]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [26] LimitClause production rule", production: :LimitClause do
    {
      "limit" => [
        %q(LIMIT 10), [:limit, RDF::Literal.new(10)]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [27] OffsetClause production rule", production: :OffsetClause do
    {
      "offset" => [
        %q(OFFSET 10), [:offset, RDF::Literal.new(10)]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [29] Update production rule", production: :Update do
    {
      "insert" => [
        "INSERT DATA {<a> <b> <c>}",
        %q((update (insertData ((triple <a> <b> <c>)))))
      ],
      "insert (LC)" => [
        "insert data {<a> <b> <c>}",
        %q((update (insertData ((triple <a> <b> <c>)))))
      ],
      "clear" => [
        "CLEAR DEFAULT",
        %q((update (clear default)))
      ],
      "clear (LC)" => [
        "clear default",
        %q((update (clear default)))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the [31] Load production rule", production: :Load do
    {
      "load iri" => [%q(LOAD <a>), %((load <a>))],
      "load iri silent" => [%q(LOAD SILENT <a>), %((load silent <a>))],
      "load into" => [%q(LOAD <a> INTO GRAPH <b>), %((load <a> <b>))],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [32] Clear production rule", production: :Clear do
    {
      "clear all" => [%q(CLEAR ALL), %((clear all))],
      "clear all (LC)" => [%q(clear all), %((clear all))],
      "clear all (Mixed)" => [%q(cLeAr AlL), %((clear all))],
      "clear all silent" => [%q(CLEAR SILENT ALL), %((clear silent all))],
      "clear default" => [%q(CLEAR DEFAULT), %((clear default))],
      "clear graph" => [%q(CLEAR GRAPH <g1>), %((clear <g1>))],
      "clear named" => [%q(CLEAR NAMED), %((clear named))],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [33] Drop production rule", production: :Drop do
    {
      "drop all" => [%q(DROP ALL), %((drop all))],
      "drop all silent" => [%q(DROP SILENT ALL), %((drop silent all))],
      "drop default" => [%q(DROP DEFAULT), %((drop default))],
      "drop graph" => [%q(DROP GRAPH <g1>), %((drop <g1>))],
      "drop named" => [%q(DROP NAMED), %((drop named))],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [34] Create production rule", production: :Create do
    {
      "create graph" => [%q(CREATE GRAPH <g1>), %((create <g1>))],
      "create graph silent" => [%q(CREATE SILENT GRAPH <g1>), %((create silent <g1>))],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [35] Add production rule", production: :Add do
    {
      "add default default" => [%q(ADD DEFAULT TO DEFAULT), %q((add default default))],
      "add iri default" => [%q(ADD <a> TO DEFAULT), %q((add <a> default))],
      "add default iri" => [%q(ADD DEFAULT TO <a>), %q((add default <a>))],
      "add graph iri default" => [%q(ADD GRAPH <a> TO DEFAULT), %q((add <a> default))],
      "add default graph iri" => [%q(ADD DEFAULT TO GRAPH <a>), %q((add default <a>))],
      "add silent iri iri" => [%q(ADD SILENT <a> TO <b>), %q((add silent <a> <b>))]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [36] Move production rule", production: :Move do
    {
      "move default default" => [%q(MOVE DEFAULT TO DEFAULT), %q((move default default))],
      "move iri default" => [%q(MOVE <a> TO DEFAULT), %q((move <a> default))],
      "move default iri" => [%q(MOVE DEFAULT TO <a>), %q((move default <a>))],
      "move graph iri default" => [%q(MOVE GRAPH <a> TO DEFAULT), %q((move <a> default))],
      "move default graph iri" => [%q(MOVE DEFAULT TO GRAPH <a>), %q((move default <a>))],
      "move silent iri iri" => [%q(MOVE SILENT <a> TO <b>), %q((move silent <a> <b>))]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [37] Copy production rule", production: :Copy do
    {
      "copy default default" => [%q(COPY DEFAULT TO DEFAULT), %q((copy default default))],
      "copy iri default" => [%q(COPY <a> TO DEFAULT), %q((copy <a> default))],
      "copy default iri" => [%q(COPY DEFAULT TO <a>), %q((copy default <a>))],
      "copy graph iri default" => [%q(COPY GRAPH <a> TO DEFAULT), %q((copy <a> default))],
      "copy default graph iri" => [%q(COPY DEFAULT TO GRAPH <a>), %q((copy default <a>))],
      "copy silent iri iri" => [%q(COPY SILENT <a> TO <b>), %q((copy silent <a> <b>))]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [45] UsingClause production rule", production: :UsingClause do
    {
      "using iri" => [
        %q(USING <a>), [:using, RDF::URI("a")]
      ],
      "using pname" => [
        %q(USING :a), [:using, RDF::URI("a")]
      ],
      "using named" => [
        %q(USING NAMED <a>), [:using, [:named, RDF::URI("a")]]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [38] InsertData production rule", production: :InsertData do
    {
      "empty triple" => [
        %q(INSERT DATA {}),
        %q((insertData ()))
      ],
      "insert triple" => [
        %q(INSERT DATA {:a foaf:knows :b .}),
        %q((insertData ((triple :a foaf:knows :b))))
      ],
      "insert graph" => [
        %q(INSERT DATA {GRAPH <http://example.org/g1> {:a foaf:knows :b .}}),
        %q((insertData ((graph <http://example.org/g1> ((triple :a foaf:knows :b))))))
      ],
      #"insert triple newline" => [
      #  %(INSERT\nDATA {:a foaf:knows :b .}),
      #  %q((insertData ((triple :a foaf:knows :b))))
      #],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [39] DeleteData production rule", production: :DeleteData do
    {
      "empty triple" => [
        %q(DELETE DATA {}),
        %q((deleteData ()))
      ],
      "delete triple" => [
        %q(DELETE DATA {:a foaf:knows :b .}),
        %q((deleteData ((triple :a foaf:knows :b))))
      ],
      "delete graph" => [
        %q(DELETE DATA {GRAPH <http://example.org/g1> {:a foaf:knows :b .}}),
        %q((deleteData ((graph <http://example.org/g1> ((triple :a foaf:knows :b))))))
      ],
      "delete triple and graph" => [
        %q(DELETE DATA {
          :A foaf:knows :B .
          GRAPH <http://example.org/g1> {:a foaf:knows :b .}
          :c foaf:knows :d .
        }),
        %q((deleteData ((triple :A foaf:knows :B)
                        (graph <http://example.org/g1> ((triple :a foaf:knows :b)))
                        (triple :c foaf:knows :d))))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  describe "when matching the [53] GroupGraphPattern production rule", production: :GroupGraphPattern do
    {
      # From data/Optional/q-opt-1.rq
      "q-opt-1.rq" => [
        "{<a><b><c> OPTIONAL {<d><e><f>}}",
        %q((leftjoin 
          (bgp (triple <a> <b> <c>))
          (bgp (triple <d> <e> <f>))))
      ],
      "q-opt-1.rq(2)" => [
        "{OPTIONAL {<d><e><f>}}",
        %q((leftjoin
          (bgp)
          (bgp (triple <d> <e> <f>))))
      ],
      # From data/Optional/q-opt-2.rq
      "q-opt-2.rq(1)" => [
        "{<a><b><c> OPTIONAL {<d><e><f>} OPTIONAL {<g><h><i>}}",
        %q((leftjoin
            (leftjoin
              (bgp (triple <a> <b> <c>))
              (bgp (triple <d> <e> <f>)))
            (bgp (triple <g> <h> <i>))))
      ],
      "q-opt-2.rq(2)" => [
        "{<a><b><c> {:x :y :z} {<d><e><f>}}",
        %q((join
            (join
              (bgp (triple <a> <b> <c>))
              (bgp (triple <x> <y> <z>)))
            (bgp (triple <d> <e> <f>))))
      ],
      "q-opt-2.rq(3)" => [
        "{<a><b><c> {:x :y :z} <d><e><f>}",
        %q((join
            (join
              (bgp (triple <a> <b> <c>))
              (bgp (triple <x> <y> <z>)))
            (bgp (triple <d> <e> <f>))))
      ],
      # From data/extracted-examples/query-4.1-q1.rq
      "query-4.1-q1.rq(1)" => [
        "{{:x :y :z} {<d><e><f>}}",
        %q((join
            (bgp (triple <x> <y> <z>))
            (bgp (triple <d> <e> <f>))))
      ],
      "query-4.1-q1.rq(2)" => [
        "{<a><b><c> {:x :y :z} UNION {<d><e><f>}}",
        %q((join
            (bgp (triple <a> <b> <c>))
            (union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))))
      ],
      # From data/Optional/q-opt-3.rq
      "q-opt-3.rq(1)" => [
        "{{:x :y :z} UNION {<d><e><f>}}",
        %q((union
            (bgp (triple <x> <y> <z>))
            (bgp (triple <d> <e> <f>))))
      ],
      "q-opt-3.rq(2)" => [
        "{GRAPH ?src { :x :y :z}}",
        %q((graph ?src (bgp (triple <x> <y> <z>))))
      ],
      "q-opt-3.rq(3)" => [
        "{<a><b><c> GRAPH <graph> {<d><e><f>}}",
        %q((join
            (bgp (triple <a> <b> <c>))
            (graph <graph>
              (bgp (triple <d> <e> <f>)))))
      ],
      "q-opt-3.rq(4)" => [
        "{ ?a :b ?c .  OPTIONAL { ?c :d ?e } . FILTER (! bound(?e))}",
        %q((filter (! (bound ?e))
            (leftjoin
              (bgp (triple ?a <b> ?c))
              (bgp (triple ?c <d> ?e)))))
      ],
      # From data/Expr1/expr-2
      "expr-2" => [
        "{ ?book dc:title ?title .
          OPTIONAL
            { ?book x:price ?price .
              FILTER (?price < 15) .
            } .
        }",
        %q((leftjoin (bgp (triple ?book <title> ?title)) (bgp (triple ?book <price> ?price)) (< ?price 15)))
      ],
      # From data-r2/filter-nested-2
      "filter-nested-2(1)" => [
        "{ :x :p ?v . { FILTER(?v = 1) } }",
        %q((join
          (bgp (triple <x> <p> ?v))
          (filter (= ?v 1)
            (bgp))))
      ],
      "filter-nested-2(2)" => [
        "{FILTER (?v = 2) FILTER (?w = 3) ?s :p ?v . ?s :q ?w . }",
        %q((filter (exprlist (= ?v 2) (= ?w 3))
          (bgp
            (triple ?s <p> ?v)
            (triple ?s <q> ?w)
          )))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end

    include_examples "BGP Patterns", "{%s}"
  end

  describe "when matching the [55] TriplesBlock production rule", production: :TriplesBlock do
    include_examples "BGP Patterns", "%s"
  end

  describe "when matching the [56] GraphPatternNotTriples production rule", production: :GraphPatternNotTriples do
    {
      "empty" => ["", EBNF::LL1::Parser::Error],
      "OptionalGraphPattern" => [
        "OPTIONAL {<d><e><f>}",
        %q((leftjoin (bgp) (bgp (triple <d> <e> <f>)))),
      ],
      "GroupOrUnionGraphPattern(1)" => [
        "{:x :y :z}",
        %q((bgp (triple <x> <y> <z>))),
      ],
      "GroupOrUnionGraphPattern(2)" => [
        "{:x :y :z} UNION {<d><e><f>}",
        %q((union
            (bgp (triple <x> <y> <z>))
            (bgp (triple <d> <e> <f>)))),
      ],
      "GroupOrUnionGraphPattern(3)" => [
        "{:x :y :z} UNION {<d><e><f>} UNION {?a ?b ?c}",
        %q((union
            (union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))
            (bgp (triple ?a ?b ?c)))),
      ],
      "GraphGraphPattern(1)" => [
        "GRAPH ?a {<d><e><f>}",
        %q((graph ?a (bgp (triple <d> <e> <f>)))),
      ],
      "GraphGraphPattern(2)" => [
        "GRAPH :a {<d><e><f>}",
        %q((graph <a> (bgp (triple <d> <e> <f>)))),
      ],
      "GraphGraphPattern(3)" => [
        "GRAPH <a> {<d><e><f>}",
        %q((graph <a> (bgp (triple <d> <e> <f>)))),
      ],
      "Bind" => [
        "BIND(?o+10 AS ?z)", %q((extend ((?z (+ ?o 10))) (bgp))),
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the [57] OptionalGraphPattern production rule", production: :OptionalGraphPattern do
    {
      "empty" => ["", EBNF::LL1::Parser::Error],
      "OptionalGraphPattern" => [
        "OPTIONAL {<d><e><f>}", %q((leftjoin (bgp (triple <d> <e> <f>)))).to_sym,
      ],
      "optional filter (1)" => [
        "OPTIONAL {?book :price ?price . FILTER (?price < 15)}",
        %q((leftjoin (bgp (triple ?book :price ?price)) (< ?price 15))).to_sym,
      ],
      "optional filter (2)" => [
        %q(OPTIONAL {?y :q ?w . FILTER(?v=2) FILTER(?w=3)}),
        %q((leftjoin (bgp (triple ?y :q ?w)) (exprlist (= ?v 2) (= ?w 3)))).to_sym,
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the [58] GraphGraphPattern production rule", production: :GraphGraphPattern do
    {
      "empty" => ["", EBNF::LL1::Parser::Error],
      "var" => [
        "GRAPH ?a {<d><e><f>}", %q((graph ?a (bgp (triple <d> <e> <f>)))),
      ],
      "pname" => [
        "GRAPH :a {<d><e><f>}", %q((graph <a> (bgp (triple <d> <e> <f>)))),
      ],
      "iri" => [
        "GRAPH <a> {<d><e><f>}", %q((graph <a> (bgp (triple <d> <e> <f>)))),
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the [60] Bind production rule", production: :Bind do
    {
      "Expression" => [
        "BIND(?o+10 AS ?z)", %q((extend (?z (+ ?o 10)))),
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the [67] GroupOrUnionGraphPattern production rule", production: :GroupOrUnionGraphPattern do
    {
      "empty" => ["", EBNF::LL1::Parser::Error],
      # From data/Optional/q-opt-3.rq
      "bgp" => [
        "{:x :y :z}", %q((bgp (triple <x> <y> <z>))),
      ],
      "union" => [
        "{:x :y :z} UNION {<d><e><f>}",
        %q((union
            (bgp (triple <x> <y> <z>))
            (bgp (triple <d> <e> <f>)))),
      ],
      "union+union" => [
        "{:x :y :z} UNION {<d><e><f>} UNION {?a ?b ?c}",
        %q((union
            (union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))
            (bgp (triple ?a ?b ?c)))),
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the [68] Filter production rule", production: :Filter do
    # Can't test against SSE, as filter also requires a BGP or other query operator
    {
      "1" => [
        %(FILTER (1)), [:filter, RDF::Literal(1)]
      ],
      "(1)" => [
        %(FILTER ((1))), [:filter, RDF::Literal(1)]
      ],
      '"foo"' => [
        %(FILTER ("foo")), [:filter, RDF::Literal("foo")]
      ],
      'STR ("foo")' => [
        %(FILTER STR ("foo")), [:filter, SPARQL::Algebra::Expression[:str, RDF::Literal("foo")]]
      ],
      'LANGMATCHES ("foo", "bar")' => [
        %(FILTER LANGMATCHES ("foo", "bar")), [:filter, SPARQL::Algebra::Expression[:langmatches, RDF::Literal("foo"), RDF::Literal("bar")]]
      ],
      "isIRI" => [
        %(FILTER isIRI ("foo")), [:filter, SPARQL::Algebra::Expression[:isIRI, RDF::Literal("foo")]]
      ],
      "REGEX" => [
        %(FILTER REGEX ("foo", "bar")), [:filter, SPARQL::Algebra::Expression[:regex, RDF::Literal("foo"), RDF::Literal("bar")]]
      ],
      "<fun>" => [
        %(FILTER <fun> ("arg")), [:filter, [RDF::URI("fun"), RDF::Literal("arg")]]
      ],
      "bound" => [
        %(FILTER BOUND (?e)), [:filter, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]]
      ],
      "(bound)" => [
        %(FILTER (BOUND (?e))), [:filter, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]]
      ],
      "!bound" => [
        %(FILTER (! BOUND (?e))), [:filter, SPARQL::Algebra::Expression[:not, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]]]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the [69] Constraint production rule", production: :Constraint do
    include_examples "FunctionCall"
    include_examples "BrackettedExpression"
    include_examples "BuiltInCall"
  end

  describe "when matching the [70] FunctionCall production rule", production: :FunctionCall do
    include_examples "FunctionCall"
  end

  describe "when matching the [71] ArgList production rule", production: :ArgList do
    {
      %q(())             => [:ArgList, RDF["nil"]],
      %q(("foo"))        => [:ArgList, RDF::Literal("foo")],
      %q(("foo", "bar")) => [:ArgList, RDF::Literal("foo"), RDF::Literal("bar")]
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata)
      end
    end
  end

  describe "when matching the [73] ConstructTemplate production rule", production: :ConstructTemplate do
    {
      "syntax-basic-03.rq" => [
        %q(?x ?y ?z),
        RDF::Query.new do
          pattern [RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y"), RDF::Query::Variable.new("z")]
        end
      ],
      "syntax-basic-05.rq" => [
        %q(?x ?y ?z),
        RDF::Query.new do
          pattern [RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y"), RDF::Query::Variable.new("z")]
        end,
      ],
      "syntax-bnodes-01.rq" => [
        %q([:p :q ]),
        RDF::Query.new do
          pattern [RDF::Node.new("b0"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/q")]
        end
      ],
      "syntax-bnodes-02.rq" => [
        %q([] :p :q),
        RDF::Query.new do
          pattern [RDF::Node.new("b0"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/q")]
        end
      ],
      "syntax-general-01.rq" => [
        %q(<a><b><c>),
        RDF::Query.new do
          pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/c")]
        end
      ],
      "syntax-general-02.rq" => [
        %q(<a><b>_:x),
        RDF::Query.new do
          pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Node("x")]
        end
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect("{#{input}}").to generate(([:ConstructTemplate] + output.patterns),
          example.metadata.merge(
            prefixes: {nil => "http://example.com/", rdf: RDF.to_uri.to_s},
            base_uri: RDF::URI("http://example.org/"),
            anon_base: "b0"))
      end
    end
  end

  # Not testing [74] ConstructTriples

  describe "when matching the [77] PropertyListNotEmpty production rule", production: :PropertyListNotEmpty do
    {
      %q(<p> <o>) => [
        %q(<p> <o>),
        [:pattern, RDF::Query::Pattern.new(predicate: RDF::URI("http://example.org/p"), object: RDF::URI("http://example.org/o"))]
      ],
      %q(?y ?z) => [
        %q(?y ?z),
        [:pattern, RDF::Query::Pattern.new(predicate: RDF::Query::Variable.new("y"), object: RDF::Query::Variable.new("z"))]
      ],
      %q(?y ?z; :b <c>) => [
        %q(?y ?z; :b <c>),
        [:pattern,
          RDF::Query::Pattern.new(predicate: RDF::Query::Variable.new("y"), object: RDF::Query::Variable.new("z")),
          RDF::Query::Pattern.new(predicate: RDF::URI("http://example.com/b"), object: RDF::URI("http://example.org/c"))]
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(
          prefixes: {nil => "http://example.com/", rdf: RDF.to_uri.to_s},
          base_uri: RDF::URI("http://example.org/"),
          anon_base: "b0"))
      end
    end
  end

  # Property paths
  describe "Property Paths [88] Path production rule", production: :Path do
    {
      %(:p?) => %((path? :p)),
      %(:p*) => %((path* :p)),
      %(:p+) => %((path+ :p)),
      %((:p+)) => %((path+ :p)),
      %(^:p) => %((reverse :p)),
      %(!^:p) => %((notoneof (reverse :p))),
      %(:p1/:p2) => %((seq :p1 :p2)),
      %(:p1|:p2) => %((alt :p1 :p2)),
      %(:p1/:p2/:p3) => %((seq (seq :p1 :p2) :p3)),
      %(:p1|:p2|:p3) => %((alt (alt :p1 :p2) :p3)),
      %((!:p)+/foaf:name) => %((seq (path+ (notoneof :p)) foaf:name)),
      %(:p1|(:p2+/:p3+)) => %((alt :p1 (seq (path+ :p2) (path+ :p3)))),
      %((((:p)*)*)*) => %((path* (path* (path* :p))))
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false, last: true))
      end
    end
  end

  # Productions that can be tested individually
  describe "individual nonterminal productions" do
    describe "when matching the [104] GraphNode production rule", production: :GraphNode do
      include_examples "Var"
      include_examples "GraphTerm"
    end

    describe "when matching the [106] VarOrTerm production rule", production: :VarOrTerm do
      include_examples "Var"
      include_examples "GraphTerm"
    end

    describe "when matching the [107] VarOrIri production rule", production: :VarOrIri do
      include_examples "Var"
      include_examples "iri"
    end

    describe "when matching the [108] Var production rule", production: :Var do
      include_examples "Var"
    end

    describe "when matching the [109] GraphTerm production rule", production: :GraphTerm do
      include_examples "GraphTerm"
    end

    describe "when matching the [110] Expression production rule", production: :Expression do
      include_examples "Expression"
    end

    describe "when matching the [111] ConditionalOrExpression production rule", production: :ConditionalOrExpression do
      include_examples "ConditionalOrExpression"
    end

    describe "when matching the [112] ConditionalAndExpression production rule", production: :ConditionalAndExpression do
      include_examples "ConditionalAndExpression"
    end

    describe "when matching the [113] ValueLogical production rule", production: :ValueLogical do
      include_examples "ValueLogical"
    end

    describe "when matching the [114] RelationalExpression production rule", production: :RelationalExpression do
      include_examples "RelationalExpression"
    end

    describe "when matching the [115] NumericExpression production rule", production: :NumericExpression do
      include_examples "NumericExpression"
    end

    describe "when matching the [116] AdditiveExpression production rule", production: :AdditiveExpression do
      include_examples "AdditiveExpression"
    end

    describe "when matching the [117] MultiplicativeExpression production rule", production: :MultiplicativeExpression do
      include_examples "MultiplicativeExpression"
    end

    describe "when matching the [118] UnaryExpression production rule", production: :UnaryExpression do
      include_examples "UnaryExpression"
    end

    describe "when matching the [119] PrimaryExpression production rule", production: :PrimaryExpression do
      include_examples "PrimaryExpression"
    end

    describe "when matching the [120] BrackettedExpression production rule", production: :BrackettedExpression do
      include_examples "BrackettedExpression"
    end

    describe "when matching the [122] BuiltInCall production rule", production: :BuiltInCall do
      include_examples "BuiltInCall"
    end

    describe "when matching the [128] iriOrFunction production rule", production: :iriOrFunction do
      include_examples "iriOrFunction"
    end

    describe "when matching the [129] RDFLiteral production rule", production: :RDFLiteral do
      include_examples "RDFLiteral"
    end

    describe "when matching the [130] NumericLiteral production rule", production: :NumericLiteral do
      include_examples "NumericLiteral"
    end
  end

  # Individual terminal productions
  describe "individual terminal productions" do
    describe "when matching the [136] iri production rule", production: :iri do
      include_examples "iri"
    end

    describe "when matching the [137] PrefixedName production rule", production: :PrefixedName do
      {
        PNAME_LN: {
          ":bar"    => RDF::URI("http://example.com/bar"),
          "foo:first" => RDF.first
        },
        PNAME_NS: {
          ":"    => RDF::URI("http://example.com/"),
          "foo:" => RDF.to_uri
        }
      }.each do |terminal, examples|
        it "recognizes the #{terminal} terminal" do |example|
          examples.each do |input, result|
            expect(input).to generate(result, example.metadata.merge(
              last: true,
              prefixes: {
                nil => "http://example.com/",
                foo: RDF.to_uri.to_s
              }))
          end
        end
      end
    end

    describe "when matching the [138] BlankNode production rule", production: :BlankNode do
      it "recognizes the BlankNode terminal" do |example|
        if output = parser(example.metadata[:production]).call(%q(_:foobar))
          v = RDF::Query::Variable.new("foobar", distinguished: false)
          expect(output.last).to eq v
          expect(output.last).not_to be_distinguished
        end
      end

      it "recognizes the ANON terminal" do |example|
        if output = parser(example.metadata[:production]).call(%q([]))
          expect(output.last).not_to be_distinguished
        end
      end
    end
  end

  context "issues", production: :QueryUnit do
    {
      issue3: [
        %(
          PREFIX a: <http://localhost/attribute_types/>
          SELECT ?entity
          WHERE {
            ?entity a:first_name 'joe' .
            ?entity a:last_name 'smith' .
            OPTIONAL {
              ?entity a:middle_name 'blah'
            }
          }
        ),
        %q{
          (prefix
           ((a: <http://localhost/attribute_types/>))
           (project
            (?entity)
            (leftjoin
             (bgp (triple ?entity a:first_name "joe") (triple ?entity a:last_name "smith"))
             (bgp (triple ?entity a:middle_name "blah"))) ))
        }
      ],
      issue7: [
        %(
          PREFIX ex: <urn:example#>

          SELECT ?subj ?pred ?obj
          WHERE {
            ?subj ?pred ?obj . {
              { ?subj ex:pred1 ?obj } UNION
              { ?subj ex:pred2 ?obj } UNION
              { ?subj ex:pred3 ?obj } UNION
              { ?subj ex:pred4 ?obj } UNION
              { ?subj ex:pred5 ?obj } UNION
              { ?subj ex:pred6 ?obj } UNION
              { ?subj ex:pred7 ?obj }
            }
          }
        ),
        %{
          (prefix ((ex: <urn:example#>))
            (project (?subj ?pred ?obj)
              (join
                (bgp (triple ?subj ?pred ?obj))
                (union
                  (union
                    (union
                      (union
                        (union
                          (union
                            (bgp (triple ?subj ex:pred1 ?obj))
                            (bgp (triple ?subj ex:pred2 ?obj)))
                          (bgp (triple ?subj ex:pred3 ?obj)))
                        (bgp (triple ?subj ex:pred4 ?obj)))
                      (bgp (triple ?subj ex:pred5 ?obj)))
                    (bgp (triple ?subj ex:pred6 ?obj)))
                  (bgp (triple ?subj ex:pred7 ?obj))))))
        }
      ],
      issue9_short: [
        %q{
          SELECT * WHERE {
            ?subj ?p ?o .
            BIND (?o AS ?v)
            ?o ?p1 "foo" .
            BIND (?p1 AS ?v2)
          }
        },
        %q{
          (extend ((?v2 ?p1))
            (join
              (extend ((?v ?o))
                (bgp (triple ?subj ?p ?o)))
              (bgp (triple ?o ?p1 "foo"))))
        }
      ],
      issue9_short2: [
        %q{
          SELECT * WHERE {
            ?subj ?p ?o .
            BIND (<http://eli.budabe.eu/eli/dir/2010/24/consil/oj> AS ?eli)
            BIND (str(?eli) AS ?eli_str)
            ?o ?p1 "foo" .
            BIND (IRI(?eli) AS ?expr_eli)
            OPTIONAL { 
              ?manif_cellar_id ?p ?manif .
            }
            BIND (?p1 AS ?v2)
          }
        },
        %q{
          (extend ((?v2 ?p1))
            (leftjoin
              (extend ((?expr_eli (iri ?eli)))
                (join
                  (extend ((?eli <http://eli.budabe.eu/eli/dir/2010/24/consil/oj>)
                           (?eli_str (str ?eli)))
                    (bgp (triple ?subj ?p ?o)))
                  (bgp (triple ?o ?p1 "foo"))))
              (bgp (triple ?manif_cellar_id ?p ?manif))))
        }
      ],
      issue21: [
        %q{
          PREFIX ext:<http://ext.com/1.0#>
          PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

          SELECT *
          WHERE {?x a ext:Subject; ?prop ?obj}
        },
        %q{
          (prefix
           ((ext: <http://ext.com/1.0#>) (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>))
           (bgp (triple ?x a ext:Subject) (triple ?x ?prop ?obj)))
        }
      ],
      issue30: [
        %q{
          PREFIX ns:<http://ns.com>
          CONSTRUCT {?item ns:link ?target}
          WHERE {
            ?item ?link ?wrapper .
            {?item ?p ?wrapper .}
            ?item ns:slot / ns:item ?target .
          }
        },
        %q{
          (prefix
           ((ns: <http://ns.com>))
           (construct ((triple ?item ns:link ?target))
            (join
             (join
              (bgp (triple ?item ?link ?wrapper))
              (bgp (triple ?item ?p ?wrapper)))
             (path ?item (seq ns:slot ns:item) ?target))))
        }
      ],
      issue32: [
        %q{
          SELECT * WHERE {
              ?s ?p ?o
              VALUES ?s { } # Notice the empty values list
          }
        },
        %q{
          (join
            (bgp (triple ?s ?p ?o))
            (table (vars ?s)))
        }
      ],
    }.each do |title, (input, result)|
      it title do |example|
        expect(input).to generate(result, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  def parser(production = nil, **options)
    @logger = options.fetch(:logger, false)
    Proc.new do |query|
      parser = described_class.new(query, {logger: @logger, resolve_iris: true}.merge(options))
      production ? parser.parse(production) : parser
    end
  end
end
