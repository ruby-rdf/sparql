require 'pathname'

require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

describe "PrimitivesParser", '#parse' do
  
  before(:all) do
    @parser = PrimitivesParser.new
  end

end