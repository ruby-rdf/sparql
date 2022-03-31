require 'sinatra/sparql'

module SPARQL
  module Server
    # A SPARQL Protocol and Graph Store server.
    #
    # Note, this is a trivial server and implementations may consider implementing integrating it into their own Rack or Sinatra server using {Rack::SPARQL} or {Sinatra::SPARQL}.
    #
    # Implements [SPARQL 1.1 Protocol](https://www.w3.org/TR/2013/REC-sparql11-protocol-20130321/)
    # and [SPARQL 1.1 Graph Store HTTP Protocol](https://www.w3.org/TR/2013/REC-sparql11-http-rdf-update-20130321/).
    #
    # Protocol-specified dataset parameters create a merged repository as described in {Sinatra::SPARQL::Helpers#dataset} and {SPARQL::Algebra::Operator::Dataset}.
    #
    # @param [RDF::Dataset] dataset (RDF::Repository.new)
    # @param [Hash{Symbol => Object}] options
    # @return [Sinatra::Base]
    def application(dataset: RDF::Repository.new, **options)
      Sinatra.new do
        register Sinatra::SPARQL
        set :repository, dataset
        enable :logging
        disable :raise_errors, :show_exceptions if settings.production?

        mime_type :jsonld, "application/ld+json"
        mime_type :normalize, "application/normalized+n-quads"
        mime_type :sparql, "application/sparql-query"
        mime_type :ttl, "text/turtle"
        mime_type :sse, "application/sse+sparql-query"

        configure :development, :test do
          set :logging, 0
        end

        get '/' do
          if params["query"]
            query = params["query"]
            halt 403, "Update not possible using GET" if params['update']
            repo = dataset(logger: request.logger, **params)
            url = RDF::URI(request.url).tap {|u| u.query = nil}
            query = begin
              SPARQL.parse(query, base_uri: url)
            rescue SPARQL::Grammar::Parser::Error => e
              halt 400, "Error parsing query: #{e.message}"
            end
            res = query.execute(repo, 
                                logger: request.logger,
                                **options.merge(params))
            res.is_a?(RDF::Literal::Boolean) ? [res] : res
          else
            settings.sparql_options.replace(standard_prefixes: true)
            settings.sparql_options.merge!(prefixes: {
              ssd: "http://www.w3.org/ns/sparql-service-description#",
              void: "http://rdfs.org/ns/void#"
            })
            repo = dataset(**params)
            service_description(repo: repo, endpoint: url)
          end
        end

        post '/' do
          query = begin
            case request.content_type
            when %r(application/sparql-query)
              SPARQL.parse(request.body, base_uri: url)
            when %r(application/sparql-update)
              SPARQL.parse(request.body, base_uri: url, update: true)
            else
              halt 500, "No query found for #{request.content_type}"
            end
          rescue SPARQL::Grammar::Parser::Error => e
            halt 400, "Error parsing #{update ? 'update' : 'query'}: #{e.message}"
          end
          repo = dataset(logger: request.logger, **params)
          url = RDF::URI(request.url).tap {|u| u.query = nil}
          res = query.execute(repo,
                              logger: request.logger,
                              **options.merge(params))
          res.is_a?(RDF::Literal::Boolean) ? [res] : res
        end
      end
    end
    module_function :application
  end
end