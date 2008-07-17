require 'pathname'

require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'
		#'http://xmlns.com/foaf/0.1/' / 'foaf:knows' / 'foaf:name'
		#'<' ([^<>"{}|^`\]-[#x00-#x20])* '>'
		# 		( [A-Za-z0-9] / '.' )
describe "IriParser", '#parse' do
  
  before(:all) do
    @parser = IriParser.new
  end
  
  it "should be able to recognize an iriref in brackets" do
    the_iriref = "<xmlns.com>"
    @parser.parse(the_iriref).should_not == nil
  end
  
  it "should be able to recognize an 'iri_ref'" do
    #the_iri_ref = "<http://xmlns.com/foaf/0.1/>"
    the_iri_ref = "<xmlns.com>"
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