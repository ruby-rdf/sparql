require File.join(File.dirname(__FILE__), 'spec_helper')

describe SPARQL do
  describe "#parse" do
    it "returns an operator" do
      query = "query"
      parser = mock("Parser")
      operator = mock("Operator")
      SPARQL::Grammar::Parser.should_receive(:new).with(query, {}).and_return(parser)
      parser.should_receive(:parse).with().and_return(operator)

      SPARQL.parse(query).should == operator
    end
  end

  describe "#execute" do
  end
end
