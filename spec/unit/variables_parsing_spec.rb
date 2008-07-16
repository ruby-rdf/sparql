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