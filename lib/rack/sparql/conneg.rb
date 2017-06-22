require 'rack'
require 'sparql'

module Rack; module SPARQL
  ##
  # Rack middleware for SPARQL content negotiation.
  #
  # Uses HTTP Content Negotiation to find an appropriate RDF
  # format to serialize any result with a body being `RDF::Enumerable`.
  #
  # Override content negotiation by setting the :format option to
  # {Rack::SPARQL#initialize}.
  #
  # This endpoint also serves the fuction of Rack::LinkedData, as it will serialize
  # SPARQL results, which may be RDF Graphs
  class ContentNegotiation
    VARY = {'Vary' => 'Accept'}.freeze

    # @!attribute [r] app
    # @return [#call]
    attr_reader :app

    # @!attribute [r] options
    # @return [Hash{Symbol => Object}]
    attr_reader :options

    ##
    # @param  [#call]                  app
    # @param  [Hash{Symbol => Object}] options
    #   Other options passed to writer.
    # @option options [RDF::Format, #to_sym] :format Specific RDF writer format to use
    def initialize(app, options = {})
      @app, @options = app, options
    end

    ##
    # Handles a Rack protocol request. Parses Accept header to find appropriate mime-type and sets content_type accordingly.
    #
    # If result is `RDF::Literal::Boolean`, `RDF::Query::Results`, or `RDF::Enumerable`
    # The result is serialized using {SPARQL::Results}
    #
    # Inserts ordered content types into the environment as `ORDERED_CONTENT_TYPES` if an Accept header is present
    #
    # @param  [Hash{String => String}] env
    # @return [Array(Integer, Hash, #each)]
    # @see    http://rack.rubyforge.org/doc/SPEC.html
    def call(env)
      env['ORDERED_CONTENT_TYPES'] = parse_accept_header(env['HTTP_ACCEPT']) if env.has_key?('HTTP_ACCEPT')
      response = app.call(env)
      body = response[2].respond_to?(:body) ? response[2].body : response[2]
      case body
      when RDF::Enumerable, RDF::Query::Solutions, RDF::Literal::Boolean
        response[2] = body  # Put it back in the response, it might have been a proxy
        serialize(env, *response)
      else response
      end
    end

    ##
    # Serializes a SPARQL query result into a Rack protocol
    # response using HTTP content negotiation rules or a specified Content-Type.
    #
    # @param  [Hash{String => String}] env
    # @param  [Integer]                status
    # @param  [Hash{String => Object}] headers
    # @param  [RDF::Enumerable]        body
    # @return [Array(Integer, Hash, #each)]
    # @raise [RDF::WriterError] when no results are generated
    def serialize(env, status, headers, body)
      begin
        serialize_options = {}
        serialize_options[:content_types] = env['ORDERED_CONTENT_TYPES'] if env['ORDERED_CONTENT_TYPES']
        serialize_options.merge!(@options)
        results = ::SPARQL.serialize_results(body, serialize_options)
        raise RDF::WriterError, "can't serialize results" unless results
        headers = headers.merge(VARY).merge('Content-Type' => results.content_type) # FIXME: don't overwrite existing Vary headers
        [status, headers, [results]]
      rescue RDF::WriterError => e
        # Use this instead of not_acceptable so that headers are not lost.
        http_error(406, e.message, headers.merge(VARY))
      end
    end

    protected

    ##
    # Parses an HTTP `Accept` header, returning an array of MIME content
    # types ordered by the precedence rules defined in HTTP/1.1 Section 14.1.
    #
    # @param  [String, #to_s] header
    # @return [Array<String>]
    # @see    http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    def parse_accept_header(header)
      entries = header.to_s.split(',')
      entries.map { |e| accept_entry(e) }.sort_by(&:last).map(&:first)
    end

    def accept_entry(entry)
      type, *options = entry.delete(' ').split(';')
      quality = 0 # we sort smallest first
      options.delete_if { |e| quality = 1 - e[2..-1].to_f if e.start_with? 'q=' }
      [type, [quality, type.count('*'), 1 - options.size]]
    end

    ##
    # Outputs an HTTP `406 Not Acceptable` response.
    #
    # @param  [String, #to_s] message
    # @return [Array(Integer, Hash, #each)]
    def not_acceptable(message = nil)
      http_error(406, message, VARY)
    end

    ##
    # Outputs an HTTP `4xx` or `5xx` response.
    #
    # @param  [Integer, #to_i]         code
    # @param  [String, #to_s]          message
    # @param  [Hash{String => String}] headers
    # @return [Array(Integer, Hash, #each)]
    def http_error(code, message = nil, headers = {})
      message = http_status(code) + (message.nil? ? "\n" : " (#{message})\n")
      [code, {'Content-Type' => 'text/plain; charset=utf-8'}.merge(headers), [message]]
    end

    ##
    # Returns the standard HTTP status message for the given status `code`.
    #
    # @param  [Integer, #to_i] code
    # @return [String]
    def http_status(code)
      [code, Rack::Utils::HTTP_STATUS_CODES[code]].join(' ')
    end
  end # class ContentNegotiation
end; end # module Rack::SPARQL
