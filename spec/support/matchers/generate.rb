require 'rspec/matchers'
require 'amazing_print'

RSpec::Matchers.define :generate do |expected, options|
  def parser(**options)
    Proc.new do |query|
      parser = SPARQL::Grammar::Parser.new(query, logger: options[:logger], resolve_iris: true, **options)
      options[:production] ? parser.parse(options[:production]) : parser.parse
    end
  end

  def normalize(obj)
    if obj.is_a?(String)
      obj.gsub(/\s+/m, ' ').
        gsub(/\s+\)/m, ')').
        gsub(/\(\s+/m, '(').
        strip
    else
      obj
    end
  end

  match do |input|
    case
    when expected == EBNF::LL1::Parser::Error
      expect {parser(**options).call(input)}.to raise_error(expected)
    when options[:last]
      # Only look at end of production
      @actual = parser(**options).call(input).last
      if expected.is_a?(String)
        expect(normalize(@actual.to_sxp)).to eq normalize(expected)
      else
        expect(@actual).to eq expected
      end
    when options[:shift]
      @actual = parser(**options).call(input)[1..-1]
      expect(@actual).to eq expected
    when expected.nil?
      @actual = parser(**options).call(input)
      expect(@actual).to be_nil
    when expected.is_a?(String)
      @actual = parser(**options).call(input).to_sxp
      expect(normalize(@actual)).to eq normalize(expected)
    when expected.is_a?(Symbol)
      @actual = parser(**options).call(input)
      expect(@actual.to_sxp).to eq expected.to_s
    else
      @actual = parser(**options).call(input)
      expect(@actual).to eq expected
    end
  end
  
  failure_message do |input|
    "Input        : #{input}\n"
    case expected
    when String
      "Expected     : #{expected}\n"
    else
      "Expected     : #{expected.ai}\n" +
      "Expected(sse): #{expected.to_sxp}\n"
    end +
    case input
    when String
      "Actual       : #{actual}\n"
    else
      "Actual       : #{actual.ai}\n" +
      "Actual(sse)  : #{actual.to_sxp}\n"
    end +
    "Processing results:\n#{@debug.is_a?(Array) ? @debug.join("\n") : ''}"
  end
end
