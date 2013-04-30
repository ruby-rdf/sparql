$:.unshift ".."
require 'spec_helper'
require 'algebra/algebra_helper'

include SPARQL::Algebra

describe SPARQL::Algebra do
  context Expression do
    context "cast values" do
      {
        # String
        "(equal (xsd:string 'foo'^^xsd:string) xsd:string)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.string, RDF::Literal.new("foo", :datatype => RDF::XSD.string)]), RDF::XSD.string),
        "(equal (xsd:string '1.0e10'^^xsd:double) xsd:string)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.string, RDF::Literal.new(1.0e10)]), RDF::XSD.string),
        "(equal (xsd:string 'foo'^^xsd:integer) xsd:string)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.string, RDF::Literal.new(1)]), RDF::XSD.string),
        "(equal (xsd:string '2011-02-20T00:00:00'^^xsd:dateTime) xsd:string)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.string, RDF::Literal.new(DateTime.now)]), RDF::XSD.string),
        "(equal (xsd:string 'foo'^^xsd:boolean) xsd:string)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.string, RDF::Literal.new(true)]), RDF::XSD.string),
        "(equal (xsd:string <foo>) xsd:string)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.string, RDF::URI("foo")]), RDF::XSD.string),
        "(equal (xsd:string 'foo') xsd:string)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.string, RDF::Literal.new("foo")]), RDF::XSD.string),

        # Double
        "(equal (xsd:double '1.0e10'^^xsd:string) xsd:double)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::Literal.new("1.0e10", :datatype => RDF::XSD.string)]), RDF::XSD.double),
        "(equal (xsd:double 'foo'^^xsd:string) xsd:double) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::Literal.new("foo", :datatype => RDF::XSD.string)]), RDF::XSD.double),
        "(equal (xsd:double '1.0e10'^^xsd:double) xsd:double)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::Literal.new(1.0e10)]), RDF::XSD.double),
        "(equal (xsd:double '1'^^xsd:integer) xsd:double)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::Literal.new(1)]), RDF::XSD.double),
        "(equal (xsd:double '2011-02-20T00:00:00'^^xsd:dateTime) xsd:double) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::Literal.new(DateTime.now)]), RDF::XSD.double),
        "(equal (xsd:double 'foo'^^xsd:boolean) xsd:double)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::Literal.new(true)]), RDF::XSD.double),
        "(equal (xsd:double <foo>) xsd:double) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::URI("foo")]), RDF::XSD.double),
        "(equal (xsd:double '1') xsd:double)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::Literal.new("1")]), RDF::XSD.double),
        "(equal (xsd:double 'foo') xsd:double) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.double, RDF::Literal.new("foo")]), RDF::XSD.double),

        # Decimal
        "(equal (xsd:decimal '1.0'^^xsd:string) xsd:decimal)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::Literal.new("1.0", :datatype => RDF::XSD.string)]), RDF::XSD.decimal),
        "(equal (xsd:decimal 'foo'^^xsd:string) xsd:decimal) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::Literal.new("foo", :datatype => RDF::XSD.string)]), RDF::XSD.decimal),
        "(equal (xsd:decimal '1.0e10'^^xsd:double) xsd:decimal) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::Literal::Double.new("1.0e10")]), RDF::XSD.decimal),
        "(equal (xsd:decimal '1'^^xsd:integer) xsd:decimal)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::Literal.new(1)]), RDF::XSD.decimal),
        "(equal (xsd:decimal '2011-02-20T00:00:00'^^xsd:dateTime) xsd:decimal) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::Literal.new(DateTime.now)]), RDF::XSD.decimal),
        "(equal (xsd:decimal 'foo'^^xsd:boolean) xsd:decimal)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::Literal.new(true)]), RDF::XSD.decimal),
        "(equal (xsd:decimal <foo>) xsd:decimal) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::URI("foo")]), RDF::XSD.decimal),
        "(equal (xsd:decimal '1.0') xsd:decimal)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::Literal.new("1.0")]), RDF::XSD.decimal),
        "(equal (xsd:decimal 'foo') xsd:decimal) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.decimal, RDF::Literal.new("foo")]), RDF::XSD.decimal),

        # Integer
        "(equal (xsd:integer '1'^^xsd:string) xsd:integer)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::Literal.new("1", :datatype => RDF::XSD.string)]), RDF::XSD.integer),
        "(equal (xsd:integer 'foo'^^xsd:string) xsd:integer) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::Literal.new("foo", :datatype => RDF::XSD.string)]), RDF::XSD.integer),
        "(equal (xsd:integer '1.0e10'^^xsd:double) xsd:integer) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::Literal::Double.new("1.0e10")]), RDF::XSD.integer),
        "(equal (xsd:integer '1'^^xsd:integer) xsd:integer)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::Literal.new(1)]), RDF::XSD.integer),
        "(equal (xsd:integer '2011-02-20T00:00:00'^^xsd:dateTime) xsd:integer) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::Literal.new(DateTime.now)]), RDF::XSD.integer),
        "(equal (xsd:integer 'foo'^^xsd:boolean) xsd:integer)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::Literal.new(true)]), RDF::XSD.integer),
        "(equal (xsd:integer <foo>) xsd:integer) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::URI("foo")]), RDF::XSD.integer),
        "(equal (xsd:integer '1') xsd:integer)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::Literal.new("1")]), RDF::XSD.integer),
        "(equal (xsd:integer 'foo') xsd:integer) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.integer, RDF::Literal.new("foo")]), RDF::XSD.integer),

        # DateTime
        "(equal (xsd:dateTime '2011-02-20T00:00:00'^^xsd:string) xsd:dateTime)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal.new("1", :datatype => RDF::XSD.string)]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime '1'^^xsd:string) xsd:dateTime) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal.new("1", :datatype => RDF::XSD.string)]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime 'foo'^^xsd:string) xsd:dateTime) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal.new("foo", :datatype => RDF::XSD.string)]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime '1.0e10'^^xsd:double) xsd:dateTime) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal::Double.new("1.0e10")]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime '2011-02-20T00:00:00'^^xsd:dateTime) xsd:dateTime)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal.new(DateTime.now)]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime 'foo'^^xsd:boolean) xsd:dateTime) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal.new(true)]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime <foo>) xsd:dateTime) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::URI("foo")]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime '1') xsd:dateTime) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal.new("1")]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime 'foo') xsd:dateTime) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal.new("foo")]), RDF::XSD.dateTime),
        "(equal (xsd:dateTime '2011-02-20T00:00:00'^^xsd:string) xsd:dateTime)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.dateTime, RDF::Literal.new("2011-02-20T00:00:00", :datatype => RDF::XSD.string)]), RDF::XSD.dateTime),

        # Boolean
        "(equal (xsd:boolean '1'^^xsd:string) xsd:boolean)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal.new("1", :datatype => RDF::XSD.string)]), RDF::XSD.boolean),
        "(equal (xsd:boolean 'foo'^^xsd:string) xsd:boolean)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal.new("foo", :datatype => RDF::XSD.string)]), RDF::XSD.boolean),
        "(equal (xsd:boolean 'foo'^^xsd:string) xsd:boolean)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal.new("foo", :datatype => RDF::XSD.string)]), RDF::XSD.boolean),
        "(equal (xsd:boolean '1.0e10'^^xsd:double) xsd:boolean)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal::Double.new("1.0e10")]), RDF::XSD.boolean),
        "(equal (xsd:boolean '1'^^xsd:boolean) xsd:boolean)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal.new(1)]), RDF::XSD.boolean),
        "(equal (xsd:boolean '2011-02-20T00:00:00'^^xsd:dateTime) xsd:boolean) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal.new(DateTime.now)]), RDF::XSD.boolean),
        "(equal (xsd:boolean 'foo'^^xsd:boolean) xsd:boolean)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal.new(true)]), RDF::XSD.boolean),
        "(equal (xsd:boolean <foo>) xsd:boolean) raises TypeError" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::URI("foo")]), RDF::XSD.boolean),
        "(equal (xsd:boolean '1') xsd:boolean)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal.new("1")]), RDF::XSD.boolean),
        "(equal (xsd:boolean 'foo') xsd:boolean)" =>
          Operator::Equal.new(Operator::Datatype.new([RDF::XSD.boolean, RDF::Literal.new("foo")]), RDF::XSD.boolean),
      }.each do |spec, op|
        it spec do
          if spec =~ /raises/
            lambda { op.evaluate }.should raise_error(TypeError)
          else
            op.evaluate.should == RDF::Literal::TRUE
          end
        end
      end
    end
  end
end
