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
    # @option options [Hash] :host_authorization
    #   A hash of options to host_authorization, to be used by the Rack::Protection::HostAuthorization middleware.
    # @return [Sinatra::Base]
    def application(dataset: RDF::Repository.new, **options)
      Sinatra.new do
        register Sinatra::SPARQL
        set :repository, dataset
        enable :logging
        disable :raise_errors, :show_exceptions if settings.production?

        if options[:host_authorization]
          set :host_authorization, options[:host_authorization]
        end

        mime_type :jsonld, "application/ld+json"
        mime_type :normalize, "application/normalized+n-quads"
        mime_type :sparql, "application/sparql-query"
        mime_type :ttl, "text/turtle"
        mime_type :sse, "application/sse+sparql-query"

        configure :development, :test do
          set :logging, 0
        end

        get '/' do
          opts = params.inject({}) {|memo, (k,v)| memo.merge(k.to_sym => v)}
          if opts[:query]
            query = opts[:query]
            halt 403, "Update not possible using GET" if opts[:update]
            repo = dataset(logger: request.logger, **opts)
            url = RDF::URI(request.url).tap {|u| u.query = nil}
            query = begin
              SPARQL.parse(query, base_uri: url)
            rescue SPARQL::Grammar::Parser::Error => e
              halt 400, "Error parsing query: #{e.message}"
            end
            res = query.execute(repo,
                                logger: request.logger,
                                **options.merge(opts))
            res.is_a?(RDF::Literal::Boolean) ? [res] : res
          elsif opts[:update]
            halt 406, "Inappropriate update option using GET"
          else
            settings.sparql_options.replace(standard_prefixes: true)
            settings.sparql_options.merge!(prefixes: {
              ssd: "http://www.w3.org/ns/sparql-service-description#",
              void: "http://rdfs.org/ns/void#"
            })
            repo = dataset(logger: request.logger, **options)
            service_description(repo: repo, endpoint: url)
          end
        end

        post '/' do
          request_body = request.body.read
          opts = params.inject({}) { |memo, (k,v)| memo.merge(k.to_sym => v) }
          # Note, this depends on the Rack::SPARQL::ContentNegotiation
          # middleware to rewrite application/x-www-form-urlencoded to be
          # conformant with either application/sparql-query or
          # application/sparql-update.
          query = begin
            update = case request.content_type
            when %r(application/sparql-query) then false
            when %r(application/sparql-update) then true
            else
              halt 406, "No query found for #{request.content_type}"
            end
            # XXX Rack always sets input to ASCII-8BIT
            #unless request.body.external_encoding == Encoding::UTF_8
            #  halt 400, "improper body encoding: #{request.body.external_encoding}"
            #end
            SPARQL.parse(request_body, base_uri: url, update: update)
          rescue SPARQL::Grammar::Parser::Error => e
            halt 400, "Error parsing #{update ? 'update' : 'query'}: #{e.message}"
          end
          repo = dataset(logger: request.logger, **opts)
          url = RDF::URI(request.url).tap {|u| u.query = nil}
          res = query.execute(repo,
                              logger: request.logger,
                              **options.merge(opts))
          res.is_a?(RDF::Literal::Boolean) ? [res] : res
        end
      end
    end
    module_function :application
  end
end
