$:.unshift ".."
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

  # @see http://www.w3.org/TR/rdf-sparql-query/#ebv
  context "Operator" do
    describe ".arity" do
      it "returns -1" do
        @op.arity.should == -1
      end
    end

    describe "#operands" do
      it "returns an Array" do
        @op0.new.operands.should be_an Array
      end
    end

    describe "#operand" do
      # TODO
    end

    describe "#variable?" do
      it "returns true if any of the operands are variables" do
        @op1.new(RDF::Query::Variable.new(:foo)).should be_variable
      end

      it "returns false if none of the operands are variables" do
        @op1.new(RDF::Node.new).should_not be_variable
      end
    end

    describe "#constant?" do
      it "returns true if none of the operands are variables" do
        @op1.new(RDF::Node.new).should be_constant
      end

      it "returns false if any of the operands are variables" do
        @op1.new(RDF::Query::Variable.new(:foo)).should_not be_constant
      end
    end

    describe "#boolean(true)" do
      it "returns RDF::Literal::TRUE" do
        @op.new.send(:boolean, true).should eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(false)" do
      it "returns RDF::Literal::FALSE" do
        @op.new.send(:boolean, false).should eql RDF::Literal::FALSE
      end
    end

    describe "#boolean(RDF::Literal::Boolean)" do
      it "returns RDF::Literal::FALSE if the operand's lexical form is not valid" do
        @op.new.send(:boolean, RDF::Literal::Boolean.new('t')).should eql RDF::Literal::FALSE
        @op.new.send(:boolean, RDF::Literal::Boolean.new('f')).should eql RDF::Literal::FALSE
      end
    end

    describe "#boolean(RDF::Literal::TRUE)" do
      it "returns RDF::Literal::TRUE" do
        @op.new.send(:boolean, RDF::Literal::TRUE).should eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Literal::FALSE)" do
      it "returns RDF::Literal::FALSE" do
        @op.new.send(:boolean, RDF::Literal::FALSE).should eql RDF::Literal::FALSE
      end
    end

    describe "#boolean(RDF::Literal::Numeric)" do
      it "returns RDF::Literal::FALSE if the operand's lexical form is not valid" do
        @op.new.send(:boolean, RDF::Literal::Integer.new('abc')).should eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::FALSE if the operand is NaN" do
        @op.new.send(:boolean, RDF::Literal(0/0.0)).should eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::FALSE if the operand is numerically equal to zero" do
        @op.new.send(:boolean, RDF::Literal(0)).should eql RDF::Literal::FALSE
        @op.new.send(:boolean, RDF::Literal(0.0)).should eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::TRUE otherwise" do
        @op.new.send(:boolean, RDF::Literal(42)).should eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Literal) with a plain literal" do
      it "returns RDF::Literal::FALSE if the operand has zero length" do
        @op.new.send(:boolean, RDF::Literal("")).should eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::TRUE otherwise" do
        @op.new.send(:boolean, RDF::Literal("Hello")).should eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Literal::String)" do
      it "returns RDF::Literal::FALSE if the operand has zero length" do
        @op.new.send(:boolean, RDF::Literal("", :datatype => RDF::XSD.string)).should eql RDF::Literal::FALSE
      end

      it "returns RDF::Literal::TRUE otherwise" do
        @op.new.send(:boolean, RDF::Literal("Hello", :datatype => RDF::XSD.string)).should eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Literal) with a language-tagged literal" do
      it "returns RDF::Literal::TRUE" do
        @op.new.send(:boolean, RDF::Literal("Hello", :language => :en)).should eql RDF::Literal::TRUE
      end
    end

    describe "#boolean(RDF::Term)" do
      it "raises a TypeError" do
        expect { @op.new.send(:boolean, RDF::Node.new) }.to raise_error TypeError
        expect { @op.new.send(:boolean, RDF::DC.title) }.to raise_error TypeError
      end
    end
  end

  context "Operator::Nullary" do
    describe ".arity" do
      it "returns 0" do
        @op0.arity.should == 0
      end
    end
  end

  context "Operator::Unary" do
    describe ".arity" do
      it "returns 1" do
        @op1.arity.should == 1
      end
    end
  end

  context "Operator::Binary" do
    describe ".arity" do
      it "returns 2" do
        @op2.arity.should == 2
      end
    end
  end

  context "Operator::Ternary" do
    describe ".arity" do
      it "returns 3" do
        @op3.arity.should == 3
      end
    end
  end
end
