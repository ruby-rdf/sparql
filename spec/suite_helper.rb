# Spira class for manipulating test-manifest style test suites.
# Used for Turtle tests
require 'rdf/turtle'
require 'json/ld'
require_relative 'support/extensions/isomorphic'
require_relative 'support/matchers/solutions'
require_relative 'support/models'

# For now, override RDF::Utils::File.open_file to look for the file locally before attempting to retrieve it
module RDF::Util
  module File
    REMOTE_PATH = "http://w3c.github.io/rdf-tests/sparql11/"
    LOCAL_PATH = ::File.expand_path("../w3c-rdf-tests/sparql11", __FILE__) + '/'
    REMOTE_PATH_STAR = "https://w3c.github.io/rdf-star/"
    LOCAL_PATH_STAR = ::File.expand_path("../w3c-rdf-star/", __FILE__) + '/'

    class << self
      alias_method :original_open_file, :open_file
    end

    ##
    # Override to use Patron for http and https, Kernel.open otherwise.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    # @option options [Array, String] :headers
    #   HTTP Request headers.
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, **options, &block)
      case 
      when filename_or_url.to_s =~ /^file:/
        path = filename_or_url[5..-1]
        Kernel.open(path.to_s, options, &block)
      when (filename_or_url.to_s =~ %r{^#{REMOTE_PATH}} && Dir.exist?(LOCAL_PATH))
        #puts "attempt to open #{filename_or_url} locally"
        localpath = filename_or_url.to_s.sub(REMOTE_PATH, LOCAL_PATH)
        response = begin
          ::File.open(localpath)
        rescue Errno::ENOENT => e
          raise IOError, e.message
        end
        document_options = {
          base_uri:     RDF::URI(filename_or_url),
          charset:      Encoding::UTF_8,
          code:         200,
          headers:      {}
        }
        #puts "use #{filename_or_url} locally"
        document_options[:headers][:content_type] = case filename_or_url.to_s
        when /\.ttl$/    then 'text/turtle'
        when /\.nt$/     then 'application/n-triples'
        when /\.jsonld$/ then 'application/ld+json'
        else                  'unknown'
        end

        document_options[:headers][:content_type] = response.content_type if response.respond_to?(:content_type)
        # For overriding content type from test data
        document_options[:headers][:content_type] = options[:contentType] if options[:contentType]

        remote_document = RDF::Util::File::RemoteDocument.new(response.read, **document_options)
        if block_given?
          yield remote_document
        else
          remote_document
        end
      when (filename_or_url.to_s =~ %r{^#{REMOTE_PATH_STAR}} && Dir.exist?(LOCAL_PATH_STAR))
        #puts "attempt to open #{filename_or_url} locally"
        localpath = filename_or_url.to_s.sub(REMOTE_PATH_STAR, LOCAL_PATH_STAR)
        response = begin
          ::File.open(localpath)
        rescue Errno::ENOENT => e
          raise IOError, e.message
        end
        document_options = {
          base_uri:     RDF::URI(filename_or_url),
          charset:      Encoding::UTF_8,
          code:         200,
          headers:      {}
        }
        #puts "use #{filename_or_url} locally"
        document_options[:headers][:content_type] = case filename_or_url.to_s
        when /\.ttl$/    then 'text/turtle'
        when /\.nt$/     then 'application/n-triples'
        when /\.jsonld$/ then 'application/ld+json'
        else                  'unknown'
        end

        document_options[:headers][:content_type] = response.content_type if response.respond_to?(:content_type)
        # For overriding content type from test data
        document_options[:headers][:content_type] = options[:contentType] if options[:contentType]

        remote_document = RDF::Util::File::RemoteDocument.new(response.read, **document_options)
        if block_given?
          yield remote_document
        else
          remote_document
        end
      else
        original_open_file(filename_or_url, **options, &block)
      end
    end
  end
end

module SPARQL::Spec
  BASE = "http://w3c.github.io/rdf-tests/sparql11/"
  def self.sparql1_0_syntax_tests
    %w(
      syntax-sparql1
      syntax-sparql2
      syntax-sparql3
      syntax-sparql4
      syntax-sparql5
    ).map do |partial|
      "#{BASE}data-r2/#{partial}/manifest.ttl"
    end
  end

  def self.sparql1_0_tests
    %w(
      algebra
      ask
      basic
      bnode-coreference
      boolean-effective-value
      bound
      cast
      construct
      dataset
      distinct
      expr-builtin
      expr-equals
      expr-ops
      graph
      i18n
      open-world
      optional
      optional-filter
      reduced
      regex
      solution-seq
      sort
      triple-match
      type-promotion
    ).map do |partial|
      "#{BASE}data-r2/#{partial}/manifest.ttl"
    end
  end

  def self.sparql1_1_tests
    # Skips the following:
    # * entailment
    # * csv-tsv-res
    # * http-rdf-dupdate
    # * protocol
    # * service
    # * syntax-fed
    %w(
      add
      aggregates
      basic-update
      bind
      bindings
      cast
      clear
      construct
      copy
      delete-data
      delete-insert
      delete-where
      delete
      drop
      exists
      functions
      grouping
      json-res
      move
      negation
      project-expression
      property-path
      subquery
      syntax-query
      syntax-update-1
      syntax-update-2
      update-silent
      service-description
    ).map do |partial|
      "#{BASE}data-sparql11/#{partial}/manifest.ttl"
    end
  end

  def self.sparql_star_tests
    ["syntax/manifest", "eval/manifest"].map do |man|
      "https://w3c.github.io/rdf-star/tests/sparql/#{man}.jsonld"
    end
  end
end