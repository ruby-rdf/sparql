$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'sparql/algebra/sxp_extensions'

describe "Core objects #to_sxp" do
  [
    [nil, RDF.nil],
    [false, 'false'],
    [true, 'true'],
    ['', '""'],
    ['string', '"string"'],
    [:symbol, 'symbol'],
    [1, '1'],
    [1.0, '1.0'],
    [BigDecimal("10"), '10.0'],
    [1.0e1, '10.0'],
    [Float::INFINITY, "+inf.0"],
    [-Float::INFINITY, "-inf.0"],
    [Float::NAN, "nan.0"],
    [['a', 2], '("a" 2)'],
    [Time.parse("2011-03-13T11:22:33Z"), '#@2011-03-13T11:22:33Z'],
    [/foo/, '#/foo/'],
  ].each do |(value, result)|
    it "returns #{result.inspect} for #{value.inspect}" do
      expect(value.to_sxp).to eq result
    end
  end
end
