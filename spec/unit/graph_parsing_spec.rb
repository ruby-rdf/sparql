require 'pathname'

require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "GraphParser", '#parse' do
  
  before(:all) do
    @parser = GraphParser.new
  end
  
  it "should recognize triple blocks" do
    some_triple_block = '?x foaf:knows ?y'
    @parser.parse(some_triple_block).should_not == nil
    @parser.parse(some_triple_block).triples_same_subject.text_value.should == '?x foaf:knows ?y'
  end
  
  it "should recognize 'triples_same_subject'" do
    some_triple_block = '?x foaf:knows ?y'
    triples_same_subject = @parser.parse(some_triple_block).triples_same_subject
    triples_same_subject.property_list_not_empty.text_value.should == "foaf:knows ?y"
  end
  
  # it "should recognize a basic SELECT query with one variable and one triple pattern" do
  #   basic_valid_select_query = 'SELECT ?foo WHERE { ?x foaf:knows ?y . }'
  #   parser = SparqlParser.new
  #   parser.parse(basic_valid_select_query).well_formed?.should == true
  #   parser.parse(basic_valid_select_query).prologue.text_value.should == ""
  #   parser.parse(basic_valid_select_query).query_part.text_value.should == "SELECT ?foo WHERE { ?x foaf:knows ?y . }"
  #   parser.parse('SELECT ?foo ?bar WHERE { ?x foaf:knows ?y . ?z foaf:name ?y . }').should_not == nil
  # end
end