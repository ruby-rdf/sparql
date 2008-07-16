require 'pathname'

require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'
		#'SELECT ?foo WHERE { ?x foaf:knows ?y . }'
describe "SparqlParser", '#parse' do
  
  before(:all) do
  end
  
  it "should recognize a basic SELECT query with one variable and one triple pattern" do
    basic_valid_select_query = 'SELECT ?foo WHERE { ?x foaf:knows ?y . }'
    parser = SparqlParser.new
    parser.parse(basic_valid_select_query).well_formed?.should == true
    parser.parse(basic_valid_select_query).prologue.text_value.should == ""
    parser.parse(basic_valid_select_query).query_part.text_value.should == "SELECT ?foo WHERE { ?x foaf:knows ?y . }"
    parser.parse('SELECT ?foo ?bar WHERE { ?x foaf:knows ?y . ?z foaf:name ?y . }').should_not == nil
  end
  
  it "should recognize a basic SELECT query with one variable, one triple pattern, and a PREFIX declaration" do
    basic_valid_select_query_with_prologue = 'PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT ?foo WHERE { ?x foaf:knows ?y . }'
    parser = SparqlParser.new
    parser.parse(basic_valid_select_query_with_prologue).well_formed?.should == true
    parser.parse(basic_valid_select_query_with_prologue).prologue.text_value.should == "PREFIX foaf: <http://xmlns.com/foaf/0.1/>"
    parser.parse(basic_valid_select_query_with_prologue).query_part.text_value.should == "SELECT ?foo WHERE { ?x foaf:knows ?y . }"
  end
   
   it "should recognize a basic SELECT query with one variable, two triple patterns, and a PREFIX declaration" do
     query = 'PREFIX foaf: <http://xmlns.com/foaf/0.1/> SELECT ?foo WHERE { ?x foaf:knows ?y . ?z foaf:knows ?x .}'
     parser = SparqlParser.new
     parser.parse(query).well_formed?.should == true
     parser.parse(query).prologue.text_value.should == "PREFIX foaf: <http://xmlns.com/foaf/0.1/>"
     parser.parse(query).query_part.text_value.should == "SELECT ?foo WHERE { ?x foaf:knows ?y . ?z foaf:knows ?x .}"
   end
   
   it "should recognize a SELECT query with a LANGTAG" do
     query = 'SELECT ?v WHERE { ?v ?p "cat"@en }'
     parser = SparqlParser.new
     parser.parse(query).well_formed?.should == true
     parser.parse(query).prologue.text_value.should == ""
     parser.parse(query).query_part.text_value.should == 'SELECT ?v WHERE { ?v ?p "cat"@en }'
   end
   


  
  it "should recognize a CONSTRUCT query"
  it "should recognize an ASK query"
  it "should recognize a DESCRIBE query"

end