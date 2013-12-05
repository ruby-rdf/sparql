$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'

describe 'SPARQL::VERSION' do
  it "matches the VERSION file" do
    expect(SPARQL::VERSION.to_s).to eq File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).chomp
  end
end
