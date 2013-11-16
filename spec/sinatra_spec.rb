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
    body RDF::Graph.new << [RDF::Node('a'), RDF.URI('http://example/b'), "c"]
  end

  get '/solutions' do
    settings.sparql_options.merge!(:format => (params["fmt"] ? params["fmt"].to_sym : nil))
    body RDF::Query::Solutions::Enumerator.new {|y| y << RDF::Query::Solution.new(:a => RDF::Literal("b"))}
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
    repo << [RDF::URI('http://example/a'), RDF::URI('http://example/b'), "c"]
    repo << [RDF::URI('http://example/a'), RDF::URI('http://example/b'), "d", RDF::URI('http://example/e')]
    body service_description(:repository => repo, :endpoint => RDF::URI("http://example/endpoint"))
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
      expect(last_response.status).to eq 200
      expect(last_response.body).to match(/^@prefix ssd: <.*> \.$/)
      expect(last_response.body).to match(/\[ a ssd:Service;/)
      expect(last_response.body).to match(%r{ssd:name <http://example/e>})
    end
  end
  
  context "serializes graphs" do
    context "with format" do
      {
        :ntriples => %r{_:a <http://example/b> "c" \.},
        :ttl => %r{\[ <http://example/b> "c"\]}
      }.each do |fmt, expected|
        context fmt do
          it "returns serialization" do
            get '/graph', :fmt => fmt
            expect(last_response.status).to eq 200
            expect(last_response.body).to match(expected)
            expect(last_response.content_type).to eq RDF::Format.for(fmt).content_type.first
            expect(last_response.content_length).not_to eq 0
          end
        end
      end
    end
    
    context "with Accept" do
      {
        "application/n-triples" => %r{_:a <http://example/b> "c" \.},
        "application/turtle" => %r{\[ <http://example/b> "c"\]}
      }.each do |content_types, expected|
        context content_types do
          it "returns serialization" do
            get '/graph', {}, {"HTTP_ACCEPT" => content_types}
            expect(last_response.status).to eq 200
            expect(last_response.body).to match(expected)
            expect(last_response.content_type).to eq content_types
            expect(last_response.content_length).not_to eq 0
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
        :csv => /a\r\nb\r\n/m,
        :tsv => /\?a\n"b"\n/,
      }.each do |fmt, expected|
        context fmt do
          it "returns serialization" do
            get '/solutions', :fmt => fmt
            expect(last_response.status).to eq 200
            expect(last_response.body).to match(expected)
            expect(last_response.content_type).to eq SPARQL::Results::MIME_TYPES[fmt]
            expect(last_response.content_length).not_to eq 0
          end
        end
      end
    end
    
    context "with Accept" do
      {
        ::SPARQL::Results::MIME_TYPES[:json] => %r{\{\s*"head"},
        ::SPARQL::Results::MIME_TYPES[:html] => %r{<table class="sparql"},
        ::SPARQL::Results::MIME_TYPES[:xml] => %r{<\?xml version},
        ::SPARQL::Results::MIME_TYPES[:csv] => %r{a\r\nb\r\n}m,
        ::SPARQL::Results::MIME_TYPES[:tsv] => %r{\?a\n"b"\n},
      }.each do |content_type, expected|
        context content_type do
          it "returns serialization" do
            get '/solutions', {}, {"HTTP_ACCEPT" => content_type}
            expect(last_response.body).to match(expected)
            expect(last_response.content_type).to eq content_type
            expect(last_response.content_length).not_to eq 0
          end
        end
      end
    end
  end
end