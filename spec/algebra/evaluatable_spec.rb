$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'

include SPARQL::Algebra

describe SPARQL::Algebra do
  EX = RDF::EX = RDF::Vocabulary.new('http://example.org/') unless const_defined?(:EX)

  before :all do
    @op = class EvalSpec < SPARQL::Algebra::Operator
      include SPARQL::Algebra::Evaluatable
    end
  end

  describe Evaluatable do
    describe "#evaluate" do
      it "raises a NotImplementedError" do
        expect { @op.new.evaluate(nil) }.to raise_error NotImplementedError
      end
    end

    describe "#apply" do
      it "raises a NotImplementedError" do
        expect { @op.new.apply }.to raise_error NotImplementedError
      end
    end
  end

  ##########################################################################
  # UNARY OPERATORS

  # @see http://www.w3.org/TR/xpath-functions/#func-not
  describe Operator::Not do
    it_behaves_like "Evaluate", sse_examples('operator/not/boolean.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true).to_sxp_bin).to eq [:!, RDF::Literal::TRUE]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-plus
  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-add
  describe Operator::Plus do
    it_behaves_like "Evaluate", sse_examples('operator/plus/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(42).to_sxp_bin).to eq [:+, RDF::Literal(42)]
        expect(described_class.new(29, 13).to_sxp_bin).to eq [:+, RDF::Literal(29), RDF::Literal(13)]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-minus
  describe Operator::Negate do
    it_behaves_like "Evaluate", sse_examples('operator/negate/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(42).to_sxp_bin).to eq [:-, RDF::Literal(42)]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-bound
  describe Operator::Bound do
    it_behaves_like "Evaluate", sse_examples('operator/bound/variable.sse')

    describe ".evaluate(RDF::Query::Variable)" do
      it "returns an RDF::Literal::Boolean" do
        expect(described_class.evaluate(RDF::Query::Variable.new(:foo))).to be_an(RDF::Literal::Boolean)
      end
    end

    # TODO: tests with actual solution sequences.

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(RDF::Query::Variable.new(:foo)).to_sxp_bin).to eq [:bound, RDF::Query::Variable.new(:foo)]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-isIRI
  describe Operator::IsIRI do
    it_behaves_like "Evaluate", sse_examples('operator/is_iri/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(RDF::Vocab::DC.title).to_sxp_bin).to eq [:isIRI, RDF::Vocab::DC.title]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-isBlank
  describe Operator::IsBlank do
    it_behaves_like "Evaluate", sse_examples('operator/is_blank/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(RDF::Node.new(:foo)).to_sxp_bin).to eq [:isBlank, RDF::Node.new(:foo)]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-isLiteral
  describe Operator::IsLiteral do
    it_behaves_like "Evaluate", sse_examples('operator/is_literal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new("Hello").to_sxp_bin).to eq [:isLiteral, RDF::Literal("Hello")]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-str
  describe Operator::Str do
    it_behaves_like "Evaluate", sse_examples('operator/str/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(RDF::Vocab::DC.title).to_sxp_bin).to eq [:str, RDF::Vocab::DC.title]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-lang
  describe Operator::Lang do
    it_behaves_like "Evaluate", sse_examples('operator/lang/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new('Hello').to_sxp_bin).to eq [:lang, RDF::Literal('Hello')]
        expect(described_class.new(RDF::Literal('Hello', language: :en)).to_sxp_bin).to eq [:lang, RDF::Literal('Hello', language: :en)]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-datatype
  describe Operator::Datatype do
    it_behaves_like "Evaluate", sse_examples('operator/datatype/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new('Hello').to_sxp_bin).to eq [:datatype, RDF::Literal('Hello')]
        expect(described_class.new(RDF::Literal('Hello', datatype: RDF::XSD.string)).to_sxp_bin).to eq [:datatype, RDF::Literal('Hello', datatype: RDF::XSD.string)]
      end
    end
  end

  ##########################################################################
  # BINARY OPERATORS

  # @see http://www.w3.org/TR/sparql11-query/#func-logical-or
  # @see http://www.w3.org/TR/sparql11-query/#evaluation
  describe Operator::Or do
    it_behaves_like "Evaluate", sse_examples('operator/or/boolean.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true, false).to_sxp_bin).to eq [:"||", RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-logical-and
  # @see http://www.w3.org/TR/sparql11-query/#evaluation
  describe Operator::And do
    it_behaves_like "Evaluate", sse_examples('operator/and/boolean.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true, false).to_sxp_bin).to eq [:"&&", RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#OperatorMapping
  describe Operator::Equal do
    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    it_behaves_like "Evaluate", sse_examples('operator/equal/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-equal
    it_behaves_like "Evaluate", sse_examples('operator/equal/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-equal
    it_behaves_like "Evaluate", sse_examples('operator/equal/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-equal
    it_behaves_like "Evaluate", sse_examples('operator/equal/datetime.sse')

    # @see http://www.w3.org/TR/sparql11-query/#func-RDFterm-equal
    it_behaves_like "Evaluate", sse_examples('operator/equal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true, false).to_sxp_bin).to eq [:'=', RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#OperatorMapping
  describe Operator::NotEqual do
    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    it_behaves_like "Evaluate", sse_examples('operator/not_equal/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-not
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-equal
    it_behaves_like "Evaluate", sse_examples('operator/not_equal/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-not
    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-equal
    it_behaves_like "Evaluate", sse_examples('operator/not_equal/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-not
    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-equal
    it_behaves_like "Evaluate", sse_examples('operator/not_equal/datetime.sse')

    # @see http://www.w3.org/TR/sparql11-query/#func-RDFterm-equal
    it_behaves_like "Evaluate", sse_examples('operator/not_equal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true, false).to_sxp_bin).to eq [:'!=', RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#OperatorMapping
  describe Operator::LessThan do
    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    it_behaves_like "Evaluate", sse_examples('operator/less_than/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-less-than
    it_behaves_like "Evaluate", sse_examples('operator/less_than/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-less-than
    it_behaves_like "Evaluate", sse_examples('operator/less_than/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-less-than
    it_behaves_like "Evaluate", sse_examples('operator/less_than/datetime.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true, false).to_sxp_bin).to eq [:<, RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#OperatorMapping
  describe Operator::GreaterThan do
    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    it_behaves_like "Evaluate", sse_examples('operator/greater_than/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-greater-than
    it_behaves_like "Evaluate", sse_examples('operator/greater_than/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-greater-than
    it_behaves_like "Evaluate", sse_examples('operator/greater_than/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-greater-than
    it_behaves_like "Evaluate", sse_examples('operator/greater_than/datetime.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true, false).to_sxp_bin).to eq [:>, RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#OperatorMapping
  describe Operator::LessThanOrEqual do
    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    it_behaves_like "Evaluate", sse_examples('operator/less_than_or_equal/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-less-than
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-equal
    it_behaves_like "Evaluate", sse_examples('operator/less_than_or_equal/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-less-than
    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-equal
    it_behaves_like "Evaluate", sse_examples('operator/less_than_or_equal/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-less-than
    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-equal
    it_behaves_like "Evaluate", sse_examples('operator/less_than_or_equal/datetime.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true, false).to_sxp_bin).to eq [:<=, RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#OperatorMapping
  describe Operator::GreaterThanOrEqual do
    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    it_behaves_like "Evaluate", sse_examples('operator/greater_than_or_equal/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-greater-than
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-equal
    it_behaves_like "Evaluate", sse_examples('operator/greater_than_or_equal/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-greater-than
    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-equal
    it_behaves_like "Evaluate", sse_examples('operator/greater_than_or_equal/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-greater-than
    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-equal
    it_behaves_like "Evaluate", sse_examples('operator/greater_than_or_equal/datetime.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(true, false).to_sxp_bin).to eq [:>=, RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-multiply
  describe Operator::Multiply do
    it_behaves_like "Evaluate", sse_examples('operator/multiply/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(6, 7).to_sxp_bin).to eq [:*, RDF::Literal(6), RDF::Literal(7)]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-divide
  describe Operator::Divide do
    it_behaves_like "Evaluate", sse_examples('operator/divide/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(42, 7).to_sxp_bin).to eq [:'/', RDF::Literal(42), RDF::Literal(7)]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-subtract
  describe Operator::Subtract do
    it_behaves_like "Evaluate", sse_examples('operator/subtract/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(42, 13).to_sxp_bin).to eq [:-, RDF::Literal(42), RDF::Literal(13)]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-RDFterm-equal
  describe Operator::Equal do
    it_behaves_like "Evaluate", sse_examples('operator/equal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(RDF::Node(:foo), RDF::Node(:bar)).to_sxp_bin).to eq [:'=', RDF::Node(:foo), RDF::Node(:bar)]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-RDFterm-equal
  describe Operator::NotEqual do
    it_behaves_like "Evaluate", sse_examples('operator/not_equal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(RDF::Node(:foo), RDF::Node(:bar)).to_sxp_bin).to eq [:'!=', RDF::Node(:foo), RDF::Node(:bar)]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-sameTerm
  describe Operator::SameTerm do
    it_behaves_like "Evaluate", sse_examples('operator/same_term/term.sse')

    describe "#optimize" do
      it "returns RDF::Literal::TRUE if both operands are bound and the same variable" do
        v1 = Variable(:var)
        v1.bind(RDF::Query::Solution.new({var: 'foo'}))
        v2 = Variable(:var)
        expect(described_class.new(v1, v2).optimize).to eql RDF::Literal::TRUE
      end

      it "returns itself if both operands are the same variable but unbounZ" do
        v1 = Variable(:var)
        v2 = Variable(:var)
        expect(described_class.new(v1, v2).optimize).not_to eql RDF::Literal::TRUE
      end
    end

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new(RDF::Node(:foo), RDF::Node(:bar)).to_sxp_bin).to eq [:sameTerm, RDF::Node(:foo), RDF::Node(:bar)]
      end
    end
  end

  # @see http://www.w3.org/TR/sparql11-query/#func-langMatches
  describe Operator::LangMatches do
    it_behaves_like "Evaluate", sse_examples('operator/lang_matches/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new('en-US', '*').to_sxp_bin).to eq [:langMatches, RDF::Literal('en-US'), RDF::Literal('*')]
      end
    end
  end

  ##########################################################################
  # TERNARY OPERATORS

  # @see http://www.w3.org/TR/sparql11-query/#funcex-regex
  # @see http://www.w3.org/TR/xpath-functions/#func-matches
  describe Operator::Regex do
    it_behaves_like "Evaluate", sse_examples('operator/regex/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        expect(described_class.new('Alice', '^ali', 'i').to_sxp_bin).to eq [:regex, RDF::Literal('Alice'), RDF::Literal('^ali'), RDF::Literal('i')]
      end
    end
  end

  context "query forms" do
    {
      # @see http://www.w3.org/TR/sparql11-query/#QSynIRI
      %q((base <http://example.org/>
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Base.new(
          RDF::URI("http://example.org/"),
          RDF::Query.new {pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#modDistinct
      %q((distinct
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Distinct.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#evaluation
      %q((exprlist (< ?x 1))) =>
        Operator::Exprlist.new(
          Operator::LessThan.new(Variable("x"), RDF::Literal.new(1))),
      %q((exprlist (< ?x 1) (> ?y 1))) =>
        Operator::Exprlist.new(
          Operator::LessThan.new(Variable("x"), RDF::Literal.new(1)),
          Operator::GreaterThan.new(Variable("y"), RDF::Literal.new(1))),

      # @see http://www.w3.org/TR/sparql11-query/#evaluation
      %q((filter
          (< ?x 1)
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Filter.new(
          Operator::LessThan.new(Variable("x"), RDF::Literal.new(1)),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      %q((filter
          (exprlist
            (< ?x 1)
            (> ?y 1))
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Filter.new(
          Operator::Exprlist.new(
            Operator::LessThan.new(Variable("x"), RDF::Literal.new(1)),
            Operator::GreaterThan.new(Variable("y"), RDF::Literal.new(1))),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#ebv
      %q((filter ?x
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Filter.new(
          Variable("x"),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),
      %q((filter
          (= ?x <a>)
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Filter.new(
          Operator::Equal.new(Variable("x"), RDF::URI("a")),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#namedAndDefaultGraph
      %q((graph ?g
          (bgp  (triple <a> <b> 123.0)))) =>
        Operator::Graph.new(
          Variable("g"),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      %q((join
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0)))) =>
        Operator::Join.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      %q((leftjoin
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0)))) =>
        Operator::LeftJoin.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]}),
      %q((leftjoin
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0))
          (bound ?x))) =>
        Operator::LeftJoin.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]},
          Operator::Bound.new(Variable("x"))),

      # @see http://www.w3.org/TR/sparql11-query/#modOrderBy
      %q((order (<a>)
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [RDF::URI("a")],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),
      %q((order (<a> <b>)
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [RDF::URI("a"), RDF::URI("b")],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),
      %q((order ((asc 1))
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [Operator::Asc.new(RDF::Literal.new(1))],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),
      %q((order ((desc ?a))
          (bgp (triple <a> <b> ?a)))) =>
        Operator::Order.new(
          [Operator::Desc.new(Variable("a"))],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("a")]}),
      %q((order (?a ?b ?c)
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [Variable(?a), Variable(?b), Variable(?c)],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),
      %q((order (?a (asc 1) (isIRI <b>))
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [Variable(?a), Operator::Asc.new(RDF::Literal.new(1)), Operator::IsIRI.new(RDF::URI("b"))],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),

      # @see http://www.w3.org/TR/sparql11-query/#QSynIRI
      %q((prefix ((ex: <http://example.org/>))
          (bgp (triple ?s ex:p1 123.0)))) =>
        Operator::Prefix.new(
          [[:"ex:", RDF::URI("http://example.org/")]],
          RDF::Query.new {pattern [RDF::Query::Variable.new("s"), EX.p1, RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#modProjection
      %q((project (?s)
          (bgp (triple ?s <p> 123.0)))) =>
        Operator::Project.new(
          [Variable("s")],
          RDF::Query.new {pattern [Variable("s"), RDF::URI("p"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#modReduced
      %q((reduced
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Reduced.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebraEval
      %q((slice _ 100
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Slice.new(
          :_, RDF::Literal.new(100),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),
      %q((slice 1 2
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Slice.new(
          RDF::Literal.new(1), RDF::Literal.new(2),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),


      # @see http://www.w3.org/TR/sparql11-query/#sparqlBasicGraphPatterns
      %q((bgp (triple <a> <b> <c>))) => RDF::Query.new { pattern [RDF::URI("a"), RDF::URI("b"), RDF::URI("c")]},
      %q((bgp (triple ?a _:b "c"))) => RDF::Query.new { pattern [RDF::Query::Variable.new("a"), RDF::Node.new("b"), RDF::Literal.new("c")]},

      # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      %q((union
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0)))) =>
        Operator::Union.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]}),
    }.each_pair do |sse, operator|
      it "generates SSE for #{sse}" do
        expect(SXP::Reader::SPARQL.read(sse)).to eq operator.to_sxp_bin
      end

      it "parses SSE for #{sse}" do
        expect(SPARQL::Algebra::Expression.parse(sse)).to eq operator
      end
    end
  end
end
