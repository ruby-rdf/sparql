require 'rspec/matchers'

RSpec::Matchers.define :produce do |expected, info|
  match do |actual|
    expect(actual).to eq expected
  end
  
  failure_message do |actual|
    case expected
    when String
      "Expected     : #{expected.inspect}\n"
    else
      "Expected     : #{expected.inspect}\n" +
      "Expected(sse): #{expected.to_sxp}\n"
    end +
    case actual
    when String
      "Actual       : #{actual.inspect}\n"
    else
      "Actual       : #{actual.inspect}\n" +
      "Actual(sse)  : #{actual.to_sxp}\n"
    end +
    "Processing results:\n#{info.join("\n")}"
  end
end
