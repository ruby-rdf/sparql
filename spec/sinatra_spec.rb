$:.unshift "."
require 'spec_helper'
require 'sinatra/sparql'
require 'sinatra'

class SPTest < Sinatra::Base
  register Sinatra::SPARQL

  get '/' do
    body "A String"
  end

  get '/graph' do
    settings.sparql_options.merge!(:format => (params["fmt"] ? params["fmt"].to_sym : nil))
    body RDF::Graph.new << [RDF::Node('a'), RDF::URI('b'), "c"]
  end

  get '/solutions' do
    settings.sparql_options.merge!(:format => (params["fmt"] ? params["fmt"].to_sym : nil))
    body RDF::Query::Solutions.new << RDF::Query::Solution.new(:a => RDF::Literal("b"))
  end

  get '/ssd' do
    settings.sparql_options.merge!(
      :standard_prefixes => true,
      :prefixes => {
        :ssd => "http://www.w3.org/ns/sparql-service-description#",
        :void => "http://rdfs.org/ns/void#"
      }
    )
    repo = RDF::Repository.new
    repo << [RDF::URI('a'), RDF::URI('b'), "c"]
    repo << [RDF::URI('a'), RDF::URI('b'), "d", RDF::URI('e')]
    body service_description(:repository => repo, :endpoint => RDF::URI("/endpoint"))
  end
end

require 'rack/test'

describe Sinatra::SPARQL do
  include ::Rack::Test::Methods

  def app
    SPTest.new
  end

  describe "self.registered" do
    it "sets :sparql_options" do
      Sinatra::Application.sparql_options.should be_a(Hash)
    end
  end

  describe "service_description" do
    it "returns a serialized graph" do
      get '/ssd', {}, {'HTTP_ACCEPT' => 'text/turtle'}
      last_response.status.should == 200
      last_response.body.should match(/^@prefix ssd: <.*> \.$/)
      last_response.body.should match(/\[ a ssd:Service;/)
      last_response.body.should match(/ssd:name <e>/)
    end
  end
  
  context "serializes graphs" do
    context "with format" do
      {
        :ntriples => /_:a <b> "c" \./,
        :ttl => /[ <b> "c"]/
      }.each do |fmt, expected|
        context fmt do
          it "returns serialization" do
            get '/graph', :fmt => fmt
            last_response.status.should == 200
            last_response.body.should match(expected)
            last_response.content_type.should == RDF::Format.for(fmt).content_type.first
            last_response.content_length.should_not == 0
          end
        end
      end
    end
    
    context "with Accept" do
      {
        "text/plain" => /_:a <b> "c" \./,
        "text/turtle" => /[ <b> "c"]/
      }.each do |content_types, expected|
        context content_types do
          it "returns serialization" do
            get '/graph', {}, {"HTTP_ACCEPT" => content_types}
            last_response.status.should == 200
            last_response.body.should match(expected)
            last_response.content_type.should == content_types
            last_response.content_length.should_not == 0
          end
        end
      end
    end
  end

  context "serializes solutions" do
    context "with format" do
      {
        :json => /\{\s*"head"/,
        :html => /<table class="sparql"/,
        :xml => /<\?xml version/,
      }.each do |fmt, expected|
        context fmt do
          it "returns serialization" do
            get '/solutions', :fmt => fmt
            last_response.status.should == 200
            last_response.body.should match(expected)
            last_response.content_type.should == SPARQL::Results::MIME_TYPES[fmt]
            last_response.content_length.should_not == 0
          end
        end
      end
    end
    
    context "with Accept" do
      {
        ::SPARQL::Results::MIME_TYPES[:json] => /\{\s*"head"/,
        ::SPARQL::Results::MIME_TYPES[:html] => /<table class="sparql"/,
        ::SPARQL::Results::MIME_TYPES[:xml] => /<\?xml version/,
      }.each do |content_types, expected|
        context content_types do
          it "returns serialization" do
            get '/solutions', {}, {"HTTP_ACCEPT" => content_types}
            last_response.body.should match(expected)
            last_response.content_type.should == content_types
            last_response.content_length.should_not == 0
          end
        end
      end
    end
  end
end