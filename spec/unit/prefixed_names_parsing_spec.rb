require 'pathname'
#rule pn_local
#	( pn_chars_u / [0-9] ) ((pn_chars / '.') pn_chars)?
#end
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "PrefixedNamesParser", '#parse' do
  
  before(:all) do
    @parser = PrefixedNamesParser.new
  end
  
  it "should be able to recognize a common prefixed_name" do
    the_pn = "foaf:knows"
    tree = @parser.parse(the_pn)
    tree.should_not == nil
    tree.pname_ns.text_value.should == "foaf:"
    tree.pn_local.text_value.should == "knows"
  end
  
  it "should be able to recognize a prefixed_name whose local name has a leading digit (SPARQL idiosyncrasy)" do
    the_pn = "foaf:1knows"
    tree = @parser.parse(the_pn)
    tree.should_not == nil
    tree.pname_ns.text_value.should == "foaf:"
    tree.pn_local.text_value.should == "1knows"
  end
end