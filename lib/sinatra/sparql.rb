require 'sinatra/base'
require 'sinatra/sparql/extensions'
require 'rack/sparql'
require 'rdf/aggregate_repo'

module Sinatra
  ##
  # The Sinatra::SPARQL module adds {Rack::SPARQL} middleware support for responding to SPARQL requests. It is the responsibility of the application to manage the SPARQL endpoint and perform the query. The query results are then sent as the response body. {Rack::SPARQL} middleware uses content negotiation to format the results appropriately.
  #
  # To override negotiation on Content-Type, set :format in `sparql_options` to a RDF Format class, or symbol identifying a format.
  #
  # @see https://www.sinatrarb.com/extensions.html
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
      # @see https://www.w3.org/TR/sparql11-service-description
      # @see https://www.w3.org/TR/void/
      def service_description(**options)
        repository = options[:repository]

        g = RDF::Graph.new
        sd = RDF::URI("http://www.w3.org/ns/sparql-service-description#")
        void = RDF::URI("http://rdfs.org/ns/void#")
      
        node = RDF::Node.new
        g << [node, RDF.type, sd.join("#Service")]
        g << [node, sd.join("#endpoint"), RDF::URI(url(options.fetch(:endpoint, "/sparql")))]
        g << [node, sd.join("#supportedLanguage"), sd.join("#SPARQL10Query")]
        g << [node, sd.join("#supportedLanguage"), sd.join("#SPARQL11Query")]
        g << [node, sd.join("#supportedLanguage"), sd.join("#SPARQL11Update")]
        g << [node, sd.join("#supportedLanguage"), RDF::URI('http://www.w3.org/ns/rdf-star#SPARQLStarQuery')]
        g << [node, sd.join("#supportedLanguage"), RDF::URI('http://www.w3.org/ns/rdf-star#SPARQLStarUpdate')]
      
        # Input formats
        RDF::Reader.map(&:format).select(&:to_uri).each do |format|
          g << [node, sd.join("#inputFormat"), format.to_uri]
        end

        # Result formats, both RDF and SPARQL Results.
        %w(
          http://www.w3.org/ns/formats/SPARQL_Results_XML
          http://www.w3.org/ns/formats/SPARQL_Results_JSON
          http://www.w3.org/ns/formats/SPARQL_Results_CSV
          http://www.w3.org/ns/formats/SPARQL_Results_TSV
        ).each do |uri|
          g << [node, sd.join("#resultFormat"), uri]
        end

        RDF::Writer.map(&:format).select(&:to_uri).each do |format|
          g << [node, sd.join("#resultFormat"), format.to_uri]
        end

        # Features
        g << [node, sd.join("#feature"), sd.join("#DereferencesURIs")]
        #g << [node, sd.join("#feature"), sd.join("#BasicFederatedQuery")]

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

      ##
      # This either creates a merge repo, or uses the standard repository for performing the query, based on the parameters passed (`default-graph-uri` and `named-graph-uri`).
      # Loads from the datasource, unless a graph named by
      # the datasource URI already exists in the repository.
      #
      # @return [RDF::Dataset]
      # @see Algebra::Operator::Dataset
      def dataset(**options)
        logger = options.fetch(:logger, ::Logger.new(false))
        repo = settings.repository
        if %i(default-graph-uri named-graph-uri).any? {|k| options.key?(k)}        
          default_datasets = Array(options[:"default-graph-uri"]).map {|u| RDF::URI(u)}
          named_datasets = Array(options[:"named-graph-uri"]).map {|u| RDF::URI(u)}

          (default_datasets + named_datasets).each do |uri|
            load_opts = {logger: logger, graph_name: uri, base_uri: uri}
            unless repo.has_graph?(uri)
              logger.debug(options) {"=> load #{uri}"}
              repo.load(uri.to_s, **load_opts)
            end
          end

          # Create an aggregate based on queryable having just the bits we want
          aggregate = RDF::AggregateRepo.new(repo)
          named_datasets.each {|name| aggregate.named(name) if repo.has_graph?(name)}
          aggregate.default(*default_datasets.select {|name| repo.has_graph?(name)})
          aggregate
        end || settings.repository
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
      app.send(:include, ::LinkedData) if defined?(::LinkedData)
    end
  end
end

Sinatra.register(Sinatra::SPARQL)
