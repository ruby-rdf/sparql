require 'pathname'

require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "IriParser", '#parse' do
  
  before(:all) do
    @parser = IriParser.new
  end
  
  it "should be able to recognize an iriref in brackets" do
    the_iriref = "<http://xmlns.com/foaf/0.1/>"
    @parser.parse(the_iriref).should_not == nil
  end
  
  it "should be able to recognize an 'iri_ref'" do
    the_iriref = "<http://xmlns.com/foaf/0.1/>"
    @parser.parse(the_iriref).should_not == nil
  end
  
  it "should be able to recognize an 'irirefchars'" do
    the_iriref = "<http://xmlns.com/foaf/0.1/>"
    @parser.parse(the_iriref).should_not == nil
  end

  it "should be able to recognize a 'prefixed_name'" do
    the_iriref = "<http://xmlns.com/foaf/0.1/>"
    @parser.parse(the_iriref).should_not == nil
  end

end