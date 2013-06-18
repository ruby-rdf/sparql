$:.unshift "."
require 'spec_helper'
require 'rack/sparql'
require 'rack/test'

describe Rack::SPARQL do
  include ::Rack::Test::Methods

  before(:each) { @options = {}; @headers = {} }
  def app
    target_app = mock("Target Rack Application", :call => [200, @headers, @results || "A String"])

    @app ||= Rack::SPARQL::ContentNegotiation.new(target_app, @options)
  end

  context "plain test" do
    it "returns text unchanged" do
      get '/'
      last_response.body.should == 'A String'
    end
  end
  
  context "serializes graphs" do
    before(:each) do
      @options.merge!(:standard_prefixes => true)
      @results = RDF::Graph.new
    end

    context "with format" do
      %w(ntriples ttl).map(&:to_sym).each do |fmt|
        context fmt do
          before(:each) do
            @options[:format] = fmt
            @results.should_receive(:dump).with(fmt, @options).and_return(fmt.to_s)
            get '/'
          end

          it "returns serialization" do
            last_response.body.should == fmt.to_s
          end

          it "sets content type to #{RDF::Format.for(fmt).content_type.first}" do
            last_response.content_type.should == RDF::Format.for(fmt).content_type.first
          end
          
          it "sets content length" do
            last_response.content_length.should_not == 0
          end
        end
      end
    end
    
    context "with Accept" do
      {
        :ntriples => "text/plain",
        :turtle   => "text/turtle"
      }.each do |fmt, content_types|
        context content_types do
          before(:each) do
            @results.should_receive(:dump).
              with(fmt, @options.merge(:content_types => content_types.split(/,\s+/))).
              and_return(content_types.split(/,\s+/).first)
              get '/', {}, {"HTTP_ACCEPT" => content_types}
          end

          it "returns serialization" do
            last_response.body.should == content_types.split(/,\s+/).first
          end

          it "sets content type to #{content_types}" do
            last_response.content_type.should == content_types
          end
          
          it "sets content length" do
            last_response.content_length.should_not == 0
          end
        end
      end
    end
  end

  context "serializes solutions" do
    before(:each) { @results = RDF::Query::Solutions.new << RDF::Query::Solution.new(:a => RDF::Literal("b"))}

    context "with format" do
      %w(json html xml csv tsv).map(&:to_sym).each do |fmt|
        context fmt do
          before(:each) do
            @options[:format] = fmt
            @results.should_receive("to_#{fmt}".to_sym).and_return(fmt.to_s)
            get '/'
          end

          it "returns serialization" do
            last_response.status == 200
            last_response.body.should == fmt.to_s
          end

          it "sets content type to #{SPARQL::Results::MIME_TYPES[fmt]}" do
            last_response.content_type.should == SPARQL::Results::MIME_TYPES[fmt]
          end
          
          it "sets content length" do
            last_response.content_length.should_not == 0
          end
        end
      end
    end
    
    context "with Accept" do
      {
        :json => ::SPARQL::Results::MIME_TYPES[:json],
        :html => ::SPARQL::Results::MIME_TYPES[:html],
        :xml => ::SPARQL::Results::MIME_TYPES[:xml],
        :csv => ::SPARQL::Results::MIME_TYPES[:csv],
        :tsv => ::SPARQL::Results::MIME_TYPES[:tsv],
      }.each do |fmt, content_types|
        context content_types do
          before(:each) do
            @results.should_receive("to_#{fmt}").
              and_return(content_types.split(/,\s+/).first)
              get '/', {}, {"HTTP_ACCEPT" => content_types}
          end

          it "returns serialization" do
            last_response.body.should == content_types.split(/,\s+/).first
          end

          it "sets content type to #{content_types}" do
            last_response.content_type.should == content_types
          end
          
          it "sets content length" do
            last_response.content_length.should_not == 0
          end
        end
      end
    end
  end
end