$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'

describe SPARQL::Algebra do
  EX = RDF::EX = RDF::Vocabulary.new('http://example.org/') unless const_defined?(:EX)

  before :all do
    @op  = SPARQL::Algebra::Operator
    @op0 = SPARQL::Algebra::Operator::Nullary
    @op1 = SPARQL::Algebra::Operator::Unary
    @op2 = SPARQL::Algebra::Operator::Binary
    @op3 = SPARQL::Algebra::Operator::Ternary
  end

  # @see http://www.w3.org/TR/sparql11-query/#ebv
  context "Operator" do
    describe ".arity" do
      it "returns -1" do
        expect(@op.arity).to eq -1
      end
    end

    describe "#operands" do
      it "returns an Array" do
        expect(@op0.new.operands).to be_an Array
      end
    end

    describe "#operand" do
      # TODO
    end

    describe "#variable?" do
      it "returns true if any of the operands are variables" do
        expect(@op1.new(RDF::Query::Variable.new(:foo))).to be_variable
      end

      it "returns false if none of the operands are variables" do
        expect(@op1.new(RDF::Node.new)).not_to be_variable
      end
    end

    describe "#constant?" do
      it "returns true if none of the operands are variables" do
        expect(@op1.new(RDF::Node.new)).to be_constant
      end

      it "returns false if any of the operands are variables" do
        expect(@op1.new(RDF::Query::Variable.new(:foo))).not_to be_constant
      end
    end

    describe "#boolean(true)" do
      it "returns RDF::Literal::TRUE" do
        expect(@op.new.send(:boolean, true)).to eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(false)" do
      it "returns RDF::Literal::FALSE" do
        expect(@op.new.send(:boolean, false)).to eql RDF::Literal::FALSE
      end
    end

    describe "#boolean(RDF::Literal::Boolean)" do
      it "returns RDF::Literal::FALSE if the operand's lexical form is not valid" do
        expect(@op.new.send(:boolean, RDF::Literal::Boolean.new('t'))).to eql RDF::Literal::FALSE
        expect(@op.new.send(:boolean, RDF::Literal::Boolean.new('f'))).to eql RDF::Literal::FALSE
      end
    end

    describe "#boolean(RDF::Literal::TRUE)" do
      it "returns RDF::Literal::TRUE" do
        expect(@op.new.send(:boolean, RDF::Literal::TRUE)).to eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Literal::FALSE)" do
      it "returns RDF::Literal::FALSE" do
        expect(@op.new.send(:boolean, RDF::Literal::FALSE)).to eql RDF::Literal::FALSE
      end
    end

    describe "#boolean(RDF::Literal::Numeric)" do
      it "returns RDF::Literal::FALSE if the operand's lexical form is not valid" do
        expect(@op.new.send(:boolean, RDF::Literal::Integer.new('abc'))).to eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::FALSE if the operand is NaN" do
        expect(@op.new.send(:boolean, RDF::Literal(0/0.0))).to eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::FALSE if the operand is numerically equal to zero" do
        expect(@op.new.send(:boolean, RDF::Literal(0))).to eql RDF::Literal::FALSE
        expect(@op.new.send(:boolean, RDF::Literal(0.0))).to eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::TRUE otherwise" do
        expect(@op.new.send(:boolean, RDF::Literal(42))).to eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Literal) with a plain literal" do
      it "returns RDF::Literal::FALSE if the operand has zero length" do
        expect(@op.new.send(:boolean, RDF::Literal(""))).to eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::TRUE otherwise" do
        expect(@op.new.send(:boolean, RDF::Literal("Hello"))).to eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Literal::String)" do
      it "returns RDF::Literal::FALSE if the operand has zero length" do
        expect(@op.new.send(:boolean, RDF::Literal("", datatype: RDF::XSD.string))).to eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::TRUE otherwise" do
        expect(@op.new.send(:boolean, RDF::Literal("Hello", datatype: RDF::XSD.string))).to eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Literal) with a language-tagged literal" do
      it "returns RDF::Literal::TRUE" do
        expect(@op.new.send(:boolean, RDF::Literal("Hello", language: :en))).to eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Term)" do
      it "raises a TypeError" do
        expect { @op.new.send(:boolean, RDF::Node.new) }.to raise_error TypeError
        expect { @op.new.send(:boolean, RDF::Vocab::DC.title) }.to raise_error TypeError
      end
    end
  end

  context "Operator::Nullary" do
    describe ".arity" do
      it "returns 0" do
        expect(@op0.arity).to eq 0
      end
    end
  end

  context "Operator::Unary" do
    describe ".arity" do
      it "returns 1" do
        expect(@op1.arity).to eq 1
      end
    end
  end

  context "Operator::Binary" do
    describe ".arity" do
      it "returns 2" do
        expect(@op2.arity).to eq 2
      end
    end
  end

  context "Operator::Ternary" do
    describe ".arity" do
      it "returns 3" do
        expect(@op3.arity).to eq 3
      end
    end
  end
end
