require 'sinatra/base'
require 'sinatra/sparql/extensions'
require 'rack/sparql'

module Sinatra
  ##
  # The Sinatra::SPARQL module adds {Rack::SPARQL} middleware support for responding to SPARQL requests. It is the responsibility of the application to manage the SPARQL endpoint and perform the query. The query results are then sent as the response body. {Rack::SPARQL} middleware uses content negotiation to format the results appropriately.
  #
  # To override negotiation on Content-Type, set :format in `sparql_options` to a RDF Format class, or symbol identifying a format.
  #
  # @see http://www.sinatrarb.com/extensions.html
  module SPARQL
    ##
    # Helper methods.
    module Helpers
      ##
      # This is useful when a GET request is performed against a SPARQL endpoint and no query is performed. Provide a set of datasets, including a default dataset along with optional triple count, dump location, and description of the dataset.
      #
      # The results are serialized using content negotiation. For text/html, authors should generate RDFa for the serivce description directly.
      #
      # @param [Hash{Symbol => Object}] options
      # @option options [RDF::Enumerable] :repository
      #   An enumerable, typically a type of `RDF::Repository` containing the dataset used for queries against the service.
      # @option options [RDF::URI, #to_s] :endpoint
      #   URI of the service endpoint, defaults to "/sparql" in the current realm.
      # @return [RDF::Graph]
      #
      # @see http://www.w3.org/TR/sparql11-service-description
      # @see http://www.w3.org/TR/void/
      def service_description(options = {})
        repository = options[:repository]

        g = RDF::Graph.new
        sd = RDF::URI("http://www.w3.org/ns/sparql-service-description#")
        void = RDF::URI("http://rdfs.org/ns/void#")
      
        node = RDF::Node.new
        g << [node, RDF.type, sd.join("#Service")]
        g << [node, sd.join("#endpoint"), options[:endpoint] || url("/sparql")]
        g << [node, sd.join("#supportedLanguage"), sd.join("#SPARQL11Query")]
      
        # Result formats, both RDF and SPARQL Results.
        # FIXME: We should get this from the avaliable serializers
        g << [node, sd.join("#resultFormat"), RDF::URI("http://www.w3.org/ns/formats/RDF_XML")]
        g << [node, sd.join("#resultFormat"), RDF::URI("http://www.w3.org/ns/formats/Turtle")]
        g << [node, sd.join("#resultFormat"), RDF::URI("http://www.w3.org/ns/formats/RDFa")]
        g << [node, sd.join("#resultFormat"), RDF::URI("http://www.w3.org/ns/formats/N-Triples")]
        g << [node, sd.join("#resultFormat"), RDF::URI("http://www.w3.org/ns/formats/SPARQL_Results_XML")]
        g << [node, sd.join("#resultFormat"), RDF::URI("http://www.w3.org/ns/formats/SPARQL_Results_JSON")]
        g << [node, sd.join("#resultFormat"), RDF::URI("http://www.w3.org/ns/formats/SPARQL_Results_CSV")]
        g << [node, sd.join("#resultFormat"), RDF::URI("http://www.w3.org/ns/formats/SPARQL_Results_TSV")]
      
        # Features
        g << [node, sd.join("#feature"), sd.join("#DereferencesURIs")]
      
        # Datasets
        ds = RDF::Node.new
        g << [node, sd.join("#defaultDataset"), ds]
        g << [ds, RDF.type, sd.join("#Dataset")]

        # Contexts
        if repository.is_a?(RDF::Enumerable)
          graph_names = {}
          repository.each do |statement|
            graph_names[statement.graph_name] ||= 0
            graph_names[statement.graph_name] += 1
          end
          
          graph_names.each do |name, count|
            bn = RDF::Node.new
            if name
              # Add named graphs as namedGraphs
              g << [ds, sd.join("#namedGraph"), bn]
              g << [bn, RDF.type, sd.join("#NamedGraph")]
              g << [bn, sd.join("#name"), name]
              graph = RDF::Node.new
              g << [bn, sd.join("#graph"), graph]
              bn = graph
            else
              # Default graph
              g << [ds, sd.join("#defaultGraph"), bn]
              g << [bn, RDF.type, sd.join("#Graph")]
            end
            g << [bn, void.join("#triples"), count]
          end
        end
        g
      end
    end

    ##
    # * Registers {Rack::SPARQL::ContentNegotiation}
    # * adds helpers
    # * includes SPARQL, RDF and LinkedData
    # * defines `sparql_options`, which are passed to the Rack middleware available as `settings.sparql_options` and as options within the {Rack::SPARQL} middleware.
    #
    # @param  [Sinatra::Base] app
    # @return [void]
    def self.registered(app)
      options = {}
      app.set :sparql_options, options
      app.use(Rack::SPARQL::ContentNegotiation, options)
      app.helpers(Sinatra::SPARQL::Helpers)
      app.send(:include, ::SPARQL)
      app.send(:include, ::RDF)
      app.send(:include, ::LinkedData)
    end
  end
end

Sinatra.register(Sinatra::SPARQL)
