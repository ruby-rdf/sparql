# require 'pathname'
# 
# require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'
# 
# describe "GraphParser", '#parse' do
#   
#   before(:all) do
#     @parser = GraphParser.new
#   end
#   
#   it "should recognize variables" do
#     some_var = '?x'
#     @parser.parse(some_var).should_not == nil
#   end
#   
#   # it "should recognize a basic SELECT query with one variable and one triple pattern" do
#   #   basic_valid_select_query = 'SELECT ?foo WHERE { ?x foaf:knows ?y . }'
#   #   parser = SparqlParser.new
#   #   parser.parse(basic_valid_select_query).well_formed?.should == true
#   #   parser.parse(basic_valid_select_query).prologue.text_value.should == ""
#   #   parser.parse(basic_valid_select_query).query_part.text_value.should == "SELECT ?foo WHERE { ?x foaf:knows ?y . }"
#   #   parser.parse('SELECT ?foo ?bar WHERE { ?x foaf:knows ?y . ?z foaf:name ?y . }').should_not == nil
#   # end
# end