$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'rack/sparql'
require 'rack/test'

describe Rack::SPARQL do
  include ::Rack::Test::Methods

  before(:each) { @options = {}; @headers = {} }
  def app
    target_app = double("Target Rack Application", call: [200, @headers, @results || "A String"])

    @app ||= Rack::SPARQL::ContentNegotiation.new(target_app, @options)
  end

  describe "#parse_accept_header" do
    {
      "application/n-triples" => %w(application/n-triples),
      "application/n-triples,  application/turtle" => %w(application/n-triples application/turtle),
      "application/turtle;q=0.5, application/n-triples" => %w(application/n-triples application/turtle),
    }.each do |accept, content_types|
      it "returns #{content_types.inspect} given #{accept.inspect}" do
        expect(app.send(:parse_accept_header, accept)).to eq content_types
      end
    end
  end

  context "plain test" do
    it "returns text unchanged" do
      get '/'
      expect(last_response.body).to eq 'A String'
    end
  end

  context "serializes graphs" do
    before(:each) do
      @options.merge!(standard_prefixes: true)
      @results = RDF::Graph.new
    end

    context "with format" do
      %w(ntriples ttl).map(&:to_sym).each do |fmt|
        context fmt do
          before(:each) do
            @options[:format] = fmt
            expect(@results).to receive(:dump).with(fmt, @options).and_return(fmt.to_s)
            get '/'
          end

          it "returns serialization" do
            expect(last_response.body).to eq fmt.to_s
          end

          it "sets content type to #{RDF::Format.for(fmt).content_type.first}" do
            expect(last_response.content_type).to eq RDF::Format.for(fmt).content_type.first
          end
          
          it "sets content length" do
            expect(last_response.content_length).not_to eq 0
          end
        end
      end
    end
    
    context "with Accept" do
      {
        "application/n-triples"                            => :ntriples,
        "application/n-triples,  application/turtle"       => :ntriples,
        "application/turtle;q=0.5, application/n-triples" => :ntriples,
      }.each do |accepts, fmt|
        context accepts do
          before(:each) do
            writer = RDF::Writer.for(fmt)
            expect(writer).to receive(:dump).
              and_return(accepts.split(/,\s+/).first)
              get '/', {}, {"HTTP_ACCEPT" => accepts}
          end
          let(:content_type) {app.send(:parse_accept_header, accepts).first}

          it "sets content type" do
            expect(last_response.content_type).to eq content_type
          end

          it "returns serialization" do
            expect(last_response.body).to eq accepts.split(/,\s+/).first
          end
        end
      end
    end
  end

  context "serializes solutions" do
    before(:each) { @results = RDF::Query::Solutions(RDF::Query::Solution.new(a: RDF::Literal("b")))}

    context "with format" do
      %w(json html xml csv tsv).map(&:to_sym).each do |fmt|
        context fmt do
          before(:each) do
            @options[:format] = fmt
            expect(@results).to receive("to_#{fmt}".to_sym).and_return(fmt.to_s)
            get '/'
          end

          it "returns serialization" do
            expect(last_response).to be_ok
            expect(last_response.body).to eq fmt.to_s
          end

          it "sets content type to #{SPARQL::Results::MIME_TYPES[fmt]}" do
            expect(last_response.content_type).to eq SPARQL::Results::MIME_TYPES[fmt]
          end
        end
      end
    end
    
    context "with Accept" do
      {
        json: ::SPARQL::Results::MIME_TYPES[:json],
        html: ::SPARQL::Results::MIME_TYPES[:html],
        xml: ::SPARQL::Results::MIME_TYPES[:xml],
        csv: ::SPARQL::Results::MIME_TYPES[:csv],
        tsv: ::SPARQL::Results::MIME_TYPES[:tsv],
      }.each do |fmt, content_types|
        context content_types do
          before(:each) do
            expect(@results).to receive("to_#{fmt}").
              and_return(content_types.split(/,\s+/).first)
              get '/', {}, {"HTTP_ACCEPT" => content_types}
          end

          it "returns serialization" do
            expect(last_response.body).to eq content_types.split(/,\s+/).first
          end

          it "sets content type to #{content_types}" do
            expect(last_response.content_type).to eq content_types
          end
        end
      end
    end
  end
end