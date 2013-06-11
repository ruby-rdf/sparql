$:.unshift ".."
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
        lambda { @op.new.evaluate(nil) }.should raise_error NotImplementedError
      end
    end

    describe "#apply" do
      it "raises a NotImplementedError" do
        lambda { @op.new.apply }.should raise_error NotImplementedError
      end
    end
  end

  ##########################################################################
  # UNARY OPERATORS

  # @see http://www.w3.org/TR/xpath-functions/#func-not
  describe Operator::Not do
    before :all do
      @op = @not = SPARQL::Algebra::Operator::Not
    end

    verify sse_examples('operator/not/boolean.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @not.new(true).to_sxp_bin.should == [:!, RDF::Literal::TRUE]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-plus
  describe Operator::Plus do
    before :all do
      @op = @plus = SPARQL::Algebra::Operator::Plus
    end

    verify sse_examples('operator/plus/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @plus.new(42).to_sxp_bin.should == [:+, RDF::Literal(42)]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-minus
  describe Operator::Negate do
    before :all do
      @op = @minus = SPARQL::Algebra::Operator::Negate
    end

    verify sse_examples('operator/negate/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @minus.new(42).to_sxp_bin.should == [:-, RDF::Literal(42)]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-bound
  describe Operator::Bound do
    before :all do
      @op = @bound = SPARQL::Algebra::Operator::Bound
    end

    verify sse_examples('operator/bound/variable.sse')

    describe ".evaluate(RDF::Query::Variable)" do
      it "returns an RDF::Literal::Boolean" do
        @bound.evaluate(RDF::Query::Variable.new(:foo)).should be_an(RDF::Literal::Boolean)
      end
    end

    # TODO: tests with actual solution sequences.

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @bound.new(RDF::Query::Variable.new(:foo)).to_sxp_bin.should == [:bound, RDF::Query::Variable.new(:foo)]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-isIRI
  describe Operator::IsIRI do
    before :all do
      @op = @is_iri = SPARQL::Algebra::Operator::IsIRI
    end

    verify sse_examples('operator/is_iri/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @is_iri.new(RDF::DC.title).to_sxp_bin.should == [:isIRI, RDF::DC.title]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-isBlank
  describe Operator::IsBlank do
    before :all do
      @op = @is_blank = SPARQL::Algebra::Operator::IsBlank
    end

    verify sse_examples('operator/is_blank/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @is_blank.new(RDF::Node.new(:foo)).to_sxp_bin.should == [:isBlank, RDF::Node.new(:foo)]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-isLiteral
  describe Operator::IsLiteral do
    before :all do
      @op = @is_literal = SPARQL::Algebra::Operator::IsLiteral
    end

    verify sse_examples('operator/is_literal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @is_literal.new("Hello").to_sxp_bin.should == [:isLiteral, RDF::Literal("Hello")]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-str
  describe Operator::Str do
    before :all do
      @op = @str = SPARQL::Algebra::Operator::Str
    end

    verify sse_examples('operator/str/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @str.new(RDF::DC.title).to_sxp_bin.should == [:str, RDF::DC.title]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-lang
  describe Operator::Lang do
    before :all do
      @op = @lang = SPARQL::Algebra::Operator::Lang
    end

    verify sse_examples('operator/lang/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @lang.new('Hello').to_sxp_bin.should == [:lang, RDF::Literal('Hello')]
        @lang.new(RDF::Literal('Hello', :language => :en)).to_sxp_bin.should == [:lang, RDF::Literal('Hello', :language => :en)]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-datatype
  describe Operator::Datatype do
    before :all do
      @op = @datatype = SPARQL::Algebra::Operator::Datatype
    end

    verify sse_examples('operator/datatype/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @datatype.new('Hello').to_sxp_bin.should == [:datatype, RDF::Literal('Hello')]
        @datatype.new(RDF::Literal('Hello', :datatype => RDF::XSD.string)).to_sxp_bin.should == [:datatype, RDF::Literal('Hello', :datatype => RDF::XSD.string)]
      end
    end
  end

  ##########################################################################
  # BINARY OPERATORS

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-logical-or
  # @see http://www.w3.org/TR/rdf-sparql-query/#evaluation
  describe Operator::Or do
    before :all do
      @op = @or = SPARQL::Algebra::Operator::Or
    end

    verify sse_examples('operator/or/boolean.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @or.new(true, false).to_sxp_bin.should == [:"||", RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-logical-and
  # @see http://www.w3.org/TR/rdf-sparql-query/#evaluation
  describe Operator::And do
    before :all do
      @op = @and = SPARQL::Algebra::Operator::And
    end

    verify sse_examples('operator/and/boolean.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @and.new(true, false).to_sxp_bin.should == [:"&&", RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
  describe Operator::Equal do
    before :all do
      @op = @eq = SPARQL::Algebra::Operator::Equal
    end

    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    verify sse_examples('operator/equal/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-equal
    verify sse_examples('operator/equal/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-equal
    verify sse_examples('operator/equal/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-equal
    #verify sse_examples('operator/equal/datetime.sse') # FIXME in RDF.rb 0.3.0

    # @see http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal
    verify sse_examples('operator/equal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @eq.new(true, false).to_sxp_bin.should == [:'=', RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
  describe Operator::NotEqual do
    before :all do
      @op = @ne = SPARQL::Algebra::Operator::NotEqual
    end

    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    verify sse_examples('operator/not_equal/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-not
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-equal
    verify sse_examples('operator/not_equal/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-not
    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-equal
    verify sse_examples('operator/not_equal/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-not
    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-equal
    #verify sse_examples('operator/not_equal/datetime.sse') # FIXME in RDF.rb 0.3.0

    # @see http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal
    verify sse_examples('operator/not_equal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @ne.new(true, false).to_sxp_bin.should == [:'!=', RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
  describe Operator::LessThan do
    before :all do
      @op = @lt = SPARQL::Algebra::Operator::LessThan
    end

    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    verify sse_examples('operator/less_than/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-less-than
    verify sse_examples('operator/less_than/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-less-than
    verify sse_examples('operator/less_than/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-less-than
    verify sse_examples('operator/less_than/datetime.sse') # TODO: pending bug fixes to RDF.rb 0.3.x.

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @lt.new(true, false).to_sxp_bin.should == [:<, RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
  describe Operator::GreaterThan do
    before :all do
      @op = @gt = SPARQL::Algebra::Operator::GreaterThan
    end

    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    verify sse_examples('operator/greater_than/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-greater-than
    verify sse_examples('operator/greater_than/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-greater-than
    verify sse_examples('operator/greater_than/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-greater-than
    verify sse_examples('operator/greater_than/datetime.sse') # TODO: pending bug fixes to RDF.rb 0.3.x.

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @gt.new(true, false).to_sxp_bin.should == [:>, RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
  describe Operator::LessThanOrEqual do
    before :all do
      @op = @le = SPARQL::Algebra::Operator::LessThanOrEqual
    end

    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    verify sse_examples('operator/less_than_or_equal/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-less-than
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-equal
    verify sse_examples('operator/less_than_or_equal/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-less-than
    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-equal
    verify sse_examples('operator/less_than_or_equal/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-less-than
    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-equal
    verify sse_examples('operator/less_than_or_equal/datetime.sse') # TODO: pending bug fixes to RDF.rb 0.3.x.

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @le.new(true, false).to_sxp_bin.should == [:<=, RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#OperatorMapping
  describe Operator::GreaterThanOrEqual do
    before :all do
      @op = @ge = SPARQL::Algebra::Operator::GreaterThanOrEqual
    end

    # @see http://www.w3.org/TR/xpath-functions/#func-compare
    verify sse_examples('operator/greater_than_or_equal/string.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-greater-than
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-equal
    verify sse_examples('operator/greater_than_or_equal/numeric.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-greater-than
    # @see http://www.w3.org/TR/xpath-functions/#func-boolean-equal
    verify sse_examples('operator/greater_than_or_equal/boolean.sse')

    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-greater-than
    # @see http://www.w3.org/TR/xpath-functions/#func-dateTime-equal
    verify sse_examples('operator/greater_than_or_equal/datetime.sse') # TODO: pending bug fixes to RDF.rb 0.3.x.

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @ge.new(true, false).to_sxp_bin.should == [:>=, RDF::Literal::TRUE, RDF::Literal::FALSE]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-multiply
  describe Operator::Multiply do
    before :all do
      @op = @multiply = SPARQL::Algebra::Operator::Multiply
    end

    verify sse_examples('operator/multiply/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @multiply.new(6, 7).to_sxp_bin.should == [:*, RDF::Literal(6), RDF::Literal(7)]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-divide
  describe Operator::Divide do
    before :all do
      @op = @divide = SPARQL::Algebra::Operator::Divide
    end

    verify sse_examples('operator/divide/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @divide.new(42, 7).to_sxp_bin.should == [:'/', RDF::Literal(42), RDF::Literal(7)]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-add
  describe Operator::Add do
    before :all do
      @op = @add = SPARQL::Algebra::Operator::Add
    end

    verify sse_examples('operator/add/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @add.new(29, 13).to_sxp_bin.should == [:+, RDF::Literal(29), RDF::Literal(13)]
      end
    end
  end

  # @see http://www.w3.org/TR/xpath-functions/#func-numeric-subtract
  describe Operator::Subtract do
    before :all do
      @op = @subtract = SPARQL::Algebra::Operator::Subtract
    end

    verify sse_examples('operator/subtract/numeric.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @subtract.new(42, 13).to_sxp_bin.should == [:-, RDF::Literal(42), RDF::Literal(13)]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal
  describe Operator::Equal do
    before :all do
      @op = @eq = SPARQL::Algebra::Operator::Equal
    end

    verify sse_examples('operator/equal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @eq.new(RDF::Node(:foo), RDF::Node(:bar)).to_sxp_bin.should == [:'=', RDF::Node(:foo), RDF::Node(:bar)]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-RDFterm-equal
  describe Operator::NotEqual do
    before :all do
      @op = @ne = SPARQL::Algebra::Operator::NotEqual
    end

    verify sse_examples('operator/not_equal/term.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @ne.new(RDF::Node(:foo), RDF::Node(:bar)).to_sxp_bin.should == [:'!=', RDF::Node(:foo), RDF::Node(:bar)]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-sameTerm
  describe Operator::SameTerm do
    before :all do
      @op = @same_term = SPARQL::Algebra::Operator::SameTerm
    end

    verify sse_examples('operator/same_term/term.sse')

    describe "#optimize" do
      it "returns RDF::Literal::TRUE if both operands are the same variable" do
        @same_term.new(Variable(:var), Variable(:var)).optimize.should eql RDF::Literal::TRUE
      end
    end

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @same_term.new(RDF::Node(:foo), RDF::Node(:bar)).to_sxp_bin.should == [:sameTerm, RDF::Node(:foo), RDF::Node(:bar)]
      end
    end
  end

  # @see http://www.w3.org/TR/rdf-sparql-query/#func-langMatches
  describe Operator::LangMatches do
    before :all do
      @op = @lang_matches = SPARQL::Algebra::Operator::LangMatches
    end

    verify sse_examples('operator/lang_matches/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @lang_matches.new('en-US', '*').to_sxp_bin.should == [:langMatches, RDF::Literal('en-US'), RDF::Literal('*')]
      end
    end
  end

  ##########################################################################
  # TERNARY OPERATORS

  # @see http://www.w3.org/TR/rdf-sparql-query/#funcex-regex
  # @see http://www.w3.org/TR/xpath-functions/#func-matches
  describe Operator::Regex do
    before :all do
      @op = @regex = SPARQL::Algebra::Operator::Regex
    end

    verify sse_examples('operator/regex/literal.sse')

    describe "#to_sxp_bin" do
      it "returns the correct SSE form" do
        @regex.new('Alice', '^ali', 'i').to_sxp_bin.should == [:regex, RDF::Literal('Alice'), RDF::Literal('^ali'), RDF::Literal('i')]
      end
    end
  end

  context "query forms" do
    {
      # @see http://www.w3.org/TR/rdf-sparql-query/#QSynIRI
      %q((base <http://example.org/>
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Base.new(
          RDF::URI("http://example.org/"),
          RDF::Query.new {pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/rdf-sparql-query/#modDistinct
      %q((distinct
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Distinct.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/rdf-sparql-query/#evaluation
      %q((exprlist (< ?x 1))) =>
        Operator::Exprlist.new(
          Operator::LessThan.new(Variable("x"), RDF::Literal.new(1))),
      %q((exprlist (< ?x 1) (> ?y 1))) =>
        Operator::Exprlist.new(
          Operator::LessThan.new(Variable("x"), RDF::Literal.new(1)),
          Operator::GreaterThan.new(Variable("y"), RDF::Literal.new(1))),

      # @see http://www.w3.org/TR/rdf-sparql-query/#evaluation
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

      # @see http://www.w3.org/TR/rdf-sparql-query/#ebv
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

      # @see http://www.w3.org/TR/rdf-sparql-query/#namedAndDefaultGraph
      %q((graph ?g
          (bgp  (triple <a> <b> 123.0)))) =>
        Operator::Graph.new(
          Variable("g"),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      %q((join
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0)))) =>
        Operator::Join.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]}),

      # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
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

      # @see http://www.w3.org/TR/rdf-sparql-query/#modOrderBy
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

      # @see http://www.w3.org/TR/rdf-sparql-query/#QSynIRI
      %q((prefix ((ex: <http://example.org/>))
          (bgp (triple ?s ex:p1 123.0)))) =>
        Operator::Prefix.new(
          [[:"ex:", RDF::URI("http://example.org/")]],
          RDF::Query.new {pattern [RDF::Query::Variable.new("s"), EX.p1, RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/rdf-sparql-query/#modProjection
      %q((project (?s)
          (bgp (triple ?s <p> 123.0)))) =>
        Operator::Project.new(
          [Variable("s")],
          RDF::Query.new {pattern [Variable("s"), RDF::URI("p"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/rdf-sparql-query/#modReduced
      %q((reduced
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Reduced.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebraEval
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


      # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlTriplePatterns
      %q((triple <a> <b> <c>)) => RDF::Query::Pattern.new(RDF::URI("a"), RDF::URI("b"), RDF::URI("c")),
      %q((triple ?a _:b "c")) => RDF::Query::Pattern.new(RDF::Query::Variable.new("a"), RDF::Node.new("b"), RDF::Literal.new("c")),

      # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlBasicGraphPatterns
      %q((bgp (triple <a> <b> <c>))) => RDF::Query.new { pattern [RDF::URI("a"), RDF::URI("b"), RDF::URI("c")]},

      # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      %q((union
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0)))) =>
        Operator::Union.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]}),
    }.each_pair do |sse, operator|
      it "generates SSE for #{sse}" do
        SXP::Reader::SPARQL.read(sse).should == operator.to_sxp_bin
      end

      it "parses SSE for #{sse}" do
        SPARQL::Algebra::Expression.parse(sse).should == operator
      end
    end
  end
end
