# This file is part of Sparql.rb.
# 
# Sparql.rb is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Sparql.rb is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with Sparql.rb.  If not, see <http://www.gnu.org/licenses/>.

require 'pathname'

require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "GraphParser", '#parse' do
  
  before(:all) do
    @parser = GraphParser.new
  end
  
  it "should recognize a triple block where the predicate is a prefixed name" do
    some_triple_block = '?x foaf:knows ?y'
    @parser.parse(some_triple_block).should_not == nil
    @parser.parse(some_triple_block).triples_same_subject.text_value.should == '?x foaf:knows ?y'
  end
  
  it "should recognize a triple block where the predicate is a variable" do
    some_triple_block = '?x ?theta ?y'
    @parser.parse(some_triple_block).should_not == nil
    @parser.parse(some_triple_block).triples_same_subject.text_value.should == '?x ?theta ?y'
  end
  
  it "should recognize 'triples_same_subject'" do
    some_triple_block = '?x foaf:knows ?y'
    triples_same_subject = @parser.parse(some_triple_block).triples_same_subject
    triples_same_subject.property_list_not_empty.text_value.should == "foaf:knows ?y"
  end
  
  it "should recognize 'triples_same_subject' when the predicate is a variable" do
    some_triple_block = '?x ?theta ?y'
    triples_same_subject = @parser.parse(some_triple_block).triples_same_subject
    triples_same_subject.property_list_not_empty.text_value.should == '?theta ?y'
  end
  
  it "should recognize 'triples_same_subject' when the object is a literal" # do
  #     some_triple_block = '?x ?theta "foo"'
  #     triples_same_subject = @parser.parse(some_triple_block).triples_same_subject
  #     triples_same_subject.property_list_not_empty.text_value.should == '?theta ?y "foo"'
  #   end
  
  it "should recognize a 'group_graph_pattern'" # do
  #         some_group_graph_pattern = '?v ?p "cat"'
  #         parsed = @parser.parse(some_group_graph_pattern)
  #         parsed.should_not == nil
  #       end
  
  it "should recognize a 'graph_pattern_not_triples'" # do
  #     some_graph_pattern_not_triples = '{ ?v ?p "cat" }'
  #     parsed = @parser.parse(some_graph_pattern_not_triples)
  #     parsed.should_not == nil
  #   end
  
  # it "should recognize a basic SELECT query with one variable and one triple pattern" do
  #   basic_valid_select_query = 'SELECT ?foo WHERE { ?x foaf:knows ?y . }'
  #   parser = SparqlParser.new
  #   parser.parse(basic_valid_select_query).well_formed?.should == true
  #   parser.parse(basic_valid_select_query).prologue.text_value.should == ""
  #   parser.parse(basic_valid_select_query).query_part.text_value.should == "SELECT ?foo WHERE { ?x foaf:knows ?y . }"
  #   parser.parse('SELECT ?foo ?bar WHERE { ?x foaf:knows ?y . ?z foaf:name ?y . }').should_not == nil
  # end
end