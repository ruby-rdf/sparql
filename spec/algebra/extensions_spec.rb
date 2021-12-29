$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'sparql/algebra/sxp_extensions'

describe "Core objects #to_sxp" do
  [
    [nil, RDF.nil],
    [false, 'false'],
    [true, 'true'],
  ].each do |(value, result)|
    it "returns #{result.inspect} for #{value.inspect}" do
      expect(value.to_sxp).to eq result
    end
  end
end
