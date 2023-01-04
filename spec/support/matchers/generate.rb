require 'rspec/matchers'
require 'amazing_print'

RSpec::Matchers.define :generate do |expected, options|
  def parser(**options)
    Proc.new do |query|
      parser = SPARQL::Grammar::Parser.new(query, resolve_iris: true, **options)
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
    @input = input
    @actual = input.is_a?(String) ? parser(**options).call(input) : input
    case
    when options[:last]
      # Only look at end of production
      @actual = @actual.last
      if expected.is_a?(String)
        normalize(@actual.to_sxp) == normalize(expected)
      else
        @actual == expected
      end
    when options[:shift]
      @actual = @actual[1..-1]
      @actual == expected
    when expected.nil?
      @actual.nil?
    when expected.is_a?(String)
      @actual = @actual.to_sxp
      normalize(@actual) == normalize(expected)
    when expected.is_a?(Symbol)
      @actual.to_sxp == expected.to_s
    else
      @actual == expected
    end
  rescue
    @exception = $!
    expected == EBNF::LL1::Parser::Error
  end
  
  failure_message do |input|
    "Input:\n#{@input}\n" +
    case expected
    when String
      "Expected:\n#{expected}\n"
    else
      "Expected:\n#{expected.ai}\n" +
      "Expected(sse):\n#{expected.to_sxp}\n"
    end +
    case input
    when String
      "Actual:\n#{actual}\n"
    else
      "Actual:\n#{actual.ai}\n" +
      "Actual(sse):\n#{actual.to_sxp}\n"
    end +
    (@exception ? "Exception: #{@exception}" : "") +
    "Processing results:\n#{options[:logger].to_s}"
  end
end
