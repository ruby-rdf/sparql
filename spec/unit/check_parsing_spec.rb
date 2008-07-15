require 'pathname'

require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "SparqlParser", '#parse' do
  
  before(:all) do
  end
  
  it "should recognize a SELECT query" do
    parser = SparqlParser.new
    #parser.parse('?foo').should == nil
    #parser.parse('?x foaf:knows ?y .').should == nil
    #parser.parse('WHERE { ?x foaf:knows ?y . }').should_not == nil
    parser.parse('SELECT ?foo WHERE { ?x foaf:knows ?y . }').should_not == nil
    parser.parse('SELECT ?foo ?bar WHERE { ?x foaf:knows ?y . }').should_not == nil
    parser.parse('SELECT ?foo ?bar WHERE { ?x foaf:knows ?y . ?z foaf:name ?y . }').should_not == nil
  end
  
  it "should recognize a CONSTRUCT query"
  it "should recognize an ASK query"
  it "should recognize a DESCRIBE query"

end