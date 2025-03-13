$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'suite_helper'
require 'sparql/server'
require 'rack/test'
require 'cgi'
require 'rdf/spec/matchers'

describe "SPARQL.server" do
  include ::Rack::Test::Methods

  let!(:dataset) do
    load_repo(graphs: {
      default: {data: File.read(File.expand_path('../../etc/doap.ttl', __FILE__)), format: :ttl}
    })
  end

  def app
    SPARQL::Server.application dataset: dataset
  end

  describe "service_description" do
    it "returns a serialized graph" do
      get '/', {}, {'HTTP_ACCEPT' => 'text/turtle'}
      dev = last_request.logger.instance_variable_get(:@logdev).instance_variable_get(:@dev)
      info = {logger: dev.tap(&:rewind).read}
      expect(last_response.status).to produce(200, info)
      expect(last_response.body).to match(/^@prefix ssd: <.*> \.$/)
      expect(last_response.body).to match(/\[\s+a ssd:Service;/m)
      expect(last_response.body).to match(%r{ssd:endpoint <http://example.org/>})
    end
  end

  describe "query" do
    {
      "empty ASK": {
        query: %(ASK {}),
        expected: true
      },
      "select ?name": {
        query: %(
          PREFIX doap: <http://usefulinc.com/ns/doap#>
          SELECT ?name
          WHERE {[doap:name ?name]}
        ),
        expected: RDF::Query::Solutions(
          RDF::Query::Solution.new(name: RDF::Literal("Ruby SPARQL"))
        )
      },
      query_dataset_default_graphs: {
        query: %(
          ASK {
            <https://kasei.us/2009/09/sparql/data/data1.rdf> a ?type .
            <https://kasei.us/2009/09/sparql/data/data2.rdf> a ?type .
          }
        ),
        "default-graph-uri": %w(
          https://kasei.us/2009/09/sparql/data/data1.rdf
          https://kasei.us/2009/09/sparql/data/data2.rdf
        ),
        expected: true
      },
      query_dataset_named_graphs: {
        query: %(
          ASK { GRAPH ?g { ?s ?p ?o } }
        ),
        "named-graph-uri": %w(
          https://kasei.us/2009/09/sparql/data/data2.rdf
        ),
        expected: true
      },
      query_dataset_full: {
        query: %(
          SELECT ?g ?x ?s { ?x ?y ?o  GRAPH ?g { ?s ?p ?o } }
        ),
        "default-graph-uri": %w(
          https://kasei.us/2009/09/sparql/data/data3.rdf
        ),
        "named-graph-uri": %w(
          https://kasei.us/2009/09/sparql/data/data1.rdf
          https://kasei.us/2009/09/sparql/data/data2.rdf
        ),
        expected: RDF::Query::Solutions(
          RDF::Query::Solution.new(
            g: RDF::URI('https://kasei.us/2009/09/sparql/data/data1.rdf'),
            x: RDF::URI('https://kasei.us/2009/09/sparql/data/data3.rdf'),
            s: RDF::URI('https://kasei.us/2009/09/sparql/data/data1.rdf')
          ),
          RDF::Query::Solution.new(
            g: RDF::URI('https://kasei.us/2009/09/sparql/data/data2.rdf'),
            x: RDF::URI('https://kasei.us/2009/09/sparql/data/data3.rdf'),
            s: RDF::URI('https://kasei.us/2009/09/sparql/data/data2.rdf')
          )
        )
      },
      query_multiple_dataset: {
        query: %(
          ASK
          FROM <https://kasei.us/2009/09/sparql/data/data1.rdf>
          { <https://kasei.us/2009/09/sparql/data/data1.rdf> ?p ?o }
        ),
        "default-graph-uri": %w(
          https://kasei.us/2009/09/sparql/data/data2.rdf
        ),
        expected: true,
        pending: "use data2 but query data1"
      },
      query_content_type_describe: {
        query: %(
          DESCRIBE <http://example.org/>
        ),
        expected: RDF::Graph.new,
        content_type: %(application/rdf+xml application/rdf+json text/turtle application/n-triples text/html)
      },
      query_content_type_construct: {
        query: %(
          CONSTRUCT { <s> <p> 1 } WHERE {}
        ),
        expected: RDF::Graph.new {|g|
          g << RDF::Statement.new(RDF::URI('http://example.org/s'), RDF::URI('http://example.org/p'), 1)
        },
        content_type: %(application/rdf+xml application/rdf+json text/turtle application/n-triples text/html)
      },
      update_dataset_default_graph: {
        update: %(
          PREFIX dc: <http://purl.org/dc/terms/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          CLEAR ALL ;
          INSERT DATA {
              GRAPH <https://kasei.us/2009/09/sparql/data/data1.rdf> {
                  <https://kasei.us/2009/09/sparql/data/data1.rdf> a foaf:Document
              }
          } ;
          INSERT {
              GRAPH <http://example.org/protocol-update-dataset-test/> {
                  ?s a dc:BibliographicResource
              }
          }
          WHERE {
              ?s a foaf:Document
          }
        ),
        query: %(
          ASK {
              GRAPH <http://example.org/protocol-update-dataset-test/> {
                  <https://kasei.us/2009/09/sparql/data/data1.rdf> a <http://purl.org/dc/terms/BibliographicResource>
              }
          }
        ),
        'using-graph-uri': %(https://kasei.us/2009/09/sparql/data/data1.rdf),
        expected: true
      },
      update_dataset_named_graphs: {
        update: %(
          PREFIX dc: <http://purl.org/dc/terms/>
          PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          CLEAR ALL ;
          INSERT DATA {
              GRAPH <https://kasei.us/2009/09/sparql/data/data1.rdf> { <https://kasei.us/2009/09/sparql/data/data1.rdf> a foaf:Document }
              GRAPH <https://kasei.us/2009/09/sparql/data/data2.rdf> { <https://kasei.us/2009/09/sparql/data/data2.rdf> a foaf:Document }
              GRAPH <https://kasei.us/2009/09/sparql/data/data3.rdf> { <https://kasei.us/2009/09/sparql/data/data3.rdf> a foaf:Document }
          } ;
          INSERT {
              GRAPH <http://example.org/protocol-update-dataset-named-graphs-test/> {
                  ?s a dc:BibliographicResource
              }
          }
          WHERE {
              GRAPH ?g {
                  ?s a foaf:Document
              }
          }
        ),
        query: %(
          ASK {
              GRAPH <http://example.org/protocol-update-dataset-named-graphs-test/> {
                  <https://kasei.us/2009/09/sparql/data/data1.rdf> a <http://purl.org/dc/terms/BibliographicResource> .
                  <https://kasei.us/2009/09/sparql/data/data2.rdf> a <http://purl.org/dc/terms/BibliographicResource> .
              }
              FILTER NOT EXISTS {
                  GRAPH <http://example.org/protocol-update-dataset-named-graphs-test/> {
                      <https://kasei.us/2009/09/sparql/data/data3.rdf> a <http://purl.org/dc/terms/BibliographicResource> .
                  }
              }
          }
        ),
        'using-named-graph-uri': %w(
          https://kasei.us/2009/09/sparql/data/data1.rdf
          https://kasei.us/2009/09/sparql/data/data2.rdf
        ),
        expected: true
      },
    }.each do |name, params|
      expected = params.delete(:expected)
      content_type = params.delete(:content_type) || %w(application/sparql-results+xml application/sparql-results+json)
      describe name, pending: params[:pending] do
        it "GET" do
          request '/',
                  method: :get,
                  params: params

          dev = last_request.logger.instance_variable_get(:@logdev).instance_variable_get(:@dev)
          info = {logger: dev.tap(&:rewind).read}
          expect(last_response.status).to produce(200, info)
          expect(last_response.content_type).to be_one_of(content_type)
          results = SPARQL::Client.new(last_request.url).parse_response(last_response)
          case expected
          when TrueClass, FalseClass
            expect(results).to eql expected
          else
            expect(results).to be_isomorphic(expected)
          end
        end unless params[:update]

        it "POST with URL-encoded parameters" do
          query_params = params.dup.tap do |p|
            p.delete(:update)
            p.delete(:'using-graph-uri')
            p.delete(:'using-named-graph-uri')
          end
          update_params = params.dup.tap do |p|
            p.delete(:query)
            p.delete(:'default-graph-uri')
            p.delete(:'named-graph-uri')
          end

          if update_params.key?(:update)
            request '/',
                    method: :post,
                    input: Rack::Test::Utils.build_nested_query(update_params)
            dev = last_request.logger.instance_variable_get(:@logdev).instance_variable_get(:@dev)
            info = {logger: dev.tap(&:rewind).read}
            expect(last_response.status).to produce(200, info)
          end

          request '/',
                  method: :post,
                  input: Rack::Test::Utils.build_nested_query(query_params)
          dev = last_request.logger.instance_variable_get(:@logdev).instance_variable_get(:@dev)
          info = {logger: dev.tap(&:rewind).read}
          expect(last_response.status).to produce(200, info)
          expect(last_response.content_type).to be_one_of(content_type)
          results = SPARQL::Client.new(last_request.url).parse_response(last_response)
          case expected
          when TrueClass, FalseClass
            expect(results).to eql expected
          else
            expect(results).to be_isomorphic(expected)
          end
        end

        it "POST" do
          query_params = params.dup.tap do |p|
            p.delete(:update)
            p.delete(:'using-graph-uri')
            p.delete(:'using-named-graph-uri')
          end
          query = query_params.delete(:query)
          update_params = params.dup.tap do |p|
            p.delete(:query)
            p.delete(:'default-graph-uri')
            p.delete(:'named-graph-uri')
          end
          update = update_params.delete(:update)
          info = {logger: ""}

          if update
            request '/',
                    method: :post,
                    input: update,
                    'QUERY_STRING' => Rack::Test::Utils.build_nested_query(update_params),
                    'CONTENT_TYPE' => 'application/sparql-update'
            dev = last_request.logger.instance_variable_get(:@logdev).instance_variable_get(:@dev)
            info[:logger] << CGI.unescape(dev.tap(&:rewind).read)
            expect(last_response.status).to produce(200, info)
          end

          request '/',
                  method: :post,
                  input: query,
                  'QUERY_STRING' => Rack::Test::Utils.build_nested_query(query_params),
                  'CONTENT_TYPE' => 'application/sparql-query'

          dev = last_request.logger.instance_variable_get(:@logdev).instance_variable_get(:@dev)
          info[:logger] << CGI.unescape(dev.tap(&:rewind).read)
          expect(last_response.status).to produce(200, info)
          expect(last_response.content_type).to be_one_of(content_type)
          results = SPARQL::Client.new(last_request.url).parse_response(last_response)
          case expected
          when TrueClass, FalseClass
            expect(results).to produce(expected, info)
          else
            expect(results).to be_isomorphic(expected)
          end
        end
      end
    end
  end
end