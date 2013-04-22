require 'rspec/matchers'

RSpec::Matchers.define :generate do |expected, options|
  def parser(options = {})
    @debug = options[:progress] ? 2 : []
    Proc.new do |query|
      parser = SPARQL::Grammar::Parser.new(query, {:debug => @debug, :resolve_iris => true}.merge(options))
      options[:production] ? parser.parse(options[:production]) : parser
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
      lambda {parser(example.metadata.merge(options)).call(input)}.should raise_error(expected)
    when options[:last]
      # Only look at end of production
      @actual = parser(example.metadata.merge(options)).call(input).last
      if expected.is_a?(String)
        normalize(@actual.to_sxp).should == normalize(expected)
      else
        @actual.should == expected
      end
    when options[:shift]
      @actual = parser(example.metadata.merge(options)).call(input)[1..-1]
      @actual.should == expected
    when expected.nil?
      @actual = parser(example.metadata.merge(options)).call(input)
      @actual.should be_nil
    when expected.is_a?(String)
      @actual = parser(example.metadata.merge(options)).call(input).to_sxp
      normalize(@actual).should == normalize(expected)
    when expected.is_a?(Symbol)
      @actual = parser(example.metadata.merge(options)).call(input)
      @actual.to_sxp.should == expected.to_s
    else
      @actual = parser(example.metadata.merge(options)).call(input)
      @actual.should == expected
    end
  end
  
  failure_message_for_should do |input|
    "Input        : #{input}\n"
    case expected
    when String
      "Expected     : #{expected}\n"
    else
      "Expected     : #{expected.inspect}\n" +
      "Expected(sse): #{expected.to_sxp}\n"
    end +
    case input
    when String
      "Actual       : #{actual}\n"
    else
      "Actual       : #{actual.inspect}\n" +
      "Actual(sse)  : #{actual.to_sxp}\n"
    end +
    "Processing results:\n#{@debug.is_a?(Array) ? @debug.join("\n") : ''}"
  end
end
