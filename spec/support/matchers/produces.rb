require 'rspec/matchers'

RSpec::Matchers.define :produce do |expected, info|
  match do |actual|
    expect(actual).to eq expected
  end
  
  failure_message do |actual|
    log = case info
    when Hash then  info[:logger].to_s
    when Array then info.join("\n")
    else            info.to_s
    end
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
    "Processing results:\n#{log}"
  end
end
