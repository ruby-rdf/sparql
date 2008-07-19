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

describe "VariablesParser", '#parse' do
  
  before(:all) do
    @parser = VariablesParser.new
  end
  
  it "should recognize a variable beginning with ?" do
    some_var = '?x'
    @parser.parse(some_var).should_not == nil
  end
  
  it "should recognize a variable beginning with $" do
    some_var = '$x'
    @parser.parse(some_var).should_not == nil
  end

end