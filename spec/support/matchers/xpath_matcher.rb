require 'rspec/matchers'
require 'nokogiri'

RSpec::Matchers.define :have_xpath do |xpath, value|
  match do |actual|
    @doc = Nokogiri::XML.parse(actual)
    expect(@doc).to be_a(Nokogiri::XML::Document)
    expect(@doc.root).to be_a(Nokogiri::XML::Element)
    @namespaces = @doc.namespaces.merge(
      "xml" => "http://www.w3.org/XML/1998/namespace",
      "sr"  => "http://www.w3.org/2005/sparql-results#")
    case value
    when false
      expect(@doc.root.at_xpath(xpath, @namespaces)).to be_nil
    when true
      expect(@doc.root.at_xpath(xpath, @namespaces)).not_to be_nil
    when Array
      expect(@doc.root.at_xpath(xpath, @namespaces).to_s.split(" ")).to include(*value)
    when Regexp
      expect(@doc.root.at_xpath(xpath, @namespaces).to_s).to match value
    else
      expect(@doc.root.at_xpath(xpath, @namespaces).to_s).to eq value
    end
  end
  
  failure_message_for_should do |actual|
    msg = "expected that #{xpath.inspect} would be #{value.inspect} in:\n" + actual.to_s
    msg += "was: #{@doc.root.at_xpath(xpath, @namespaces)}"
  end
end
