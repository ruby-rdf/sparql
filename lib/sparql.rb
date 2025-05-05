require 'sxp'
require 'sparql/extensions'
require 'sparql/algebra/sxp_extensions'

##
# A SPARQL for RDF.rb.
#
# @see https://www.w3.org/TR/sparql11-query
module SPARQL
  autoload :Algebra, 'sparql/algebra'
  autoload :Grammar, 'sparql/grammar'
  autoload :Results, 'sparql/results'
  autoload :Server,  'sparql/server'
  autoload :VERSION, 'sparql/version'

  # @see https://rubygems-client
  autoload :Client,  'sparql/client'

  ##
  # Parse the given SPARQL `query` string.
  #
  # @example
  #   query = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
  #
  # @param  [IO, StringIO, String, #to_s]  query
  # @param  [Hash{Symbol => Object}] options
  # @option options [Boolean] :optimize (false)
  #   Run query optimizer after parsing.
  # @option options [Boolean] :update (false)
  #   Parse starting with UpdateUnit production, QueryUnit otherwise.
  # @option options (see SPARQL::Grammar::Parser#initialize)
  # @return [RDF::Queryable]
  #   The resulting query may be executed against
  #   a `queryable` object such as an RDF::Graph
  #   or RDF::Repository. 
  # @raise  [SPARQL::Grammar::Parser::Error] on invalid input
  def self.parse(query, **options)
    parser_class = options[:use11] ? Grammar::Parser11 : Grammar::Parser
    query = parser_class.new(query, **options).parse(options[:update] ? :UpdateUnit : :QueryUnit)
    query = query.optimize if options[:optimize]
    query
  end

  ##
  # Parse and execute the given SPARQL `query` string against `queriable`.
  #
  # Requires a queryable object (such as an RDF::Repository), into which the dataset will be loaded.
  #
  # Optionally takes a list of URIs to load as default or named graphs
  # into `queryable`.
  #
  # Note, if default or named graphs are specified as options (protocol elements),
  # or the query references specific default or named graphs the graphs are either
  # presumed to be existant in `queryable` or are loaded into `queryable` depending
  # on the presense and value of the :load_datasets option.
  #
  # Attempting to load into an immutable `queryable` will result in a TypeError.
  #
  # @example
  #   repository = RDF::Repository.new
  #   results = SPARQL.execute("SELECT * WHERE { ?s ?p ?o }", repository)
  #
  # @param  [IO, StringIO, String, #to_s]  query
  # @param  [RDF::Queryable]  queryable
  # @param  [Hash{Symbol => Object}] options
  # @option options [Boolean] :optimize
  #   Optimize query before execution.
  # @option options [RDF::URI, String, Array<RDF::URI, String>] :default_graph_uri
  # @option options [RDF::URI, String, Array<RDF::URI, String>] :load_datasets
  #   One or more URIs used to initialize a new instance of `queryable` in the default graph. One or more URIs used to initialize a new instance of `queryable` in the default graph.
  # @option options [RDF::URI, String, Array<RDF::URI, String>] :named_graph_uri
  #   One or more URIs used to initialize the `queryable` as a named graph.
  # @option options (see parse)
  # @yield  [solution]
  #   each matching solution, statement or boolean
  # @yieldparam  [RDF::Statement, RDF::Query::Solution, Boolean] solution
  # @yieldreturn [void] ignored
  # @return [RDF::Graph, Boolean, RDF::Query::Solutions]
  #   Note, results may be used with {SPARQL.serialize_results} to obtain appropriate output encoding.
  # @raise  [SPARQL::MalformedQuery] on invalid input
  def self.execute(query, queryable, **options, &block)
    query = self.parse(query, **options)
    query = query.optimize(**options) if options[:optimize]
    queryable = queryable || RDF::Repository.new

    if options[:logger]
      options[:logger].debug("SPARQL.execute") {SXP::Generator.string query.to_sxp_bin}
    end

    if options.has_key?(:load_datasets)
      queryable = queryable.class.new
      [options[:default_graph_uri]].flatten.each do |uri|
        queryable.load(uri)
      end
      [options[:named_graph_uri]].flatten.each do |uri|
        queryable.load(uri, graph_name: uri)
      end
    end
    query.execute(queryable, **options, &block)
  rescue SPARQL::Grammar::Parser::Error => e
    raise MalformedQuery, e.message
  rescue TypeError => e
    raise QueryRequestRefused, e.message
  end

  ##
  # MalformedQuery
  #
  # When the value of the query type is not a legal sequence of characters in the language defined by the
  # SPARQL grammar, the MalformedQuery or QueryRequestRefused fault message must be returned. According to the
  # Fault Replaces Message Rule, if a WSDL fault is returned, including MalformedQuery, an Out Message must not
  # be returned.
  class MalformedQuery < Exception
    def title
      "Malformed Query".freeze
    end
  end

  ##
  # QueryRequestRefused
  #
  # returned when a client submits a request that the service refuses to process.
  class QueryRequestRefused < Exception
    def title
      "Query Request Refused".freeze
    end
  end
end

require 'sparql/extensions'
