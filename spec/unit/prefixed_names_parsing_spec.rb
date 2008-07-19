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