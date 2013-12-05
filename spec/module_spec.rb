$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'

describe SPARQL do
  describe "#parse" do
    it "returns an operator" do
      query = "query"
      parser = double("Parser")
      operator = double("Operator")
      expect(SPARQL::Grammar::Parser).to receive(:new).with(query, {}).and_return(parser)
      expect(parser).to receive(:parse).with().and_return(operator)

      expect(SPARQL.parse(query)).to eq operator
    end
  end

  describe "#execute" do
  end
end
