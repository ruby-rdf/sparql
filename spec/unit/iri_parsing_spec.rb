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

describe "IriParser", '#parse' do
  
  before(:all) do
    @parser = IriParser.new
  end
  
  it "should be able to recognize an iriref in brackets" do
    the_iriref = "<http://purl.org/dc/elements/1.1/title>"
    @parser.parse(the_iriref).should_not == nil
  end
  
  it "should be able to recognize an 'iri_ref'" do
    the_iri_ref = "<http://xmlns.com/foaf/0.1/>"
    @parser.parse(the_iri_ref).should_not == nil
  end
  
  # it "should be able to recognize an 'irirefchars'" do
  #   the_iriref = "<http://xmlns.com/foaf/0.1/>"
  #   @parser.parse(the_iriref).should_not == nil
  # end
  # 
  # it "should be able to recognize a 'prefixed_name'" do
  #   the_iriref = "<http://xmlns.com/foaf/0.1/>"
  #   @parser.parse(the_iriref).should_not == nil
  # end

end