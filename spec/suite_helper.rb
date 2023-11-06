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
    REMOTE_PATH = "http://w3c.github.io/rdf-tests/sparql/"
    LOCAL_PATH = ::File.expand_path("../rdf-tests/sparql/", __FILE__) + '/'
    REMOTE_PATH_STAR = "https://w3c.github.io/rdf-star/"
    LOCAL_PATH_STAR = ::File.expand_path("../rdf-star/", __FILE__) + '/'
    REMOTE_PATH_12 = "https://w3c.github.io/sparql-12/"
    LOCAL_PATH_12 = ::File.expand_path("../w3c-sparql-12/", __FILE__) + '/'
    REMOTE_PATH_PROTO = "http://kasei.us/2009/09/sparql/data/"
    LOCAL_PATH_PROTO = ::File.expand_path("../fixtures/", __FILE__) + '/'

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
      when (filename_or_url.to_s =~ %r{^#{REMOTE_PATH_12}} && Dir.exist?(LOCAL_PATH_12))
        #puts "attempt to open #{filename_or_url} locally"
        localpath = filename_or_url.to_s.sub(REMOTE_PATH_12, LOCAL_PATH_12)
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
      when (filename_or_url.to_s =~ %r{^#{REMOTE_PATH_PROTO}} && Dir.exist?(LOCAL_PATH_PROTO))
        #puts "attempt to open #{filename_or_url} locally"
        localpath = filename_or_url.to_s.sub(REMOTE_PATH_PROTO, LOCAL_PATH_PROTO)
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
      when (filename_or_url.to_s =~ %r{^somescheme})
        raise IOError, "No URL #{filename_or_url}"
      else
        original_open_file(filename_or_url, **options, &block)
      end
    end
  end
end

module SPARQL::Spec
  BASE = "http://w3c.github.io/rdf-tests/sparql/"
  def self.sparql1_0_syntax_tests
    %w(
      syntax-sparql1
      syntax-sparql2
      syntax-sparql3
      syntax-sparql4
      syntax-sparql5
    ).map do |partial|
      "#{BASE}sparql10/#{partial}/manifest.ttl"
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
      "#{BASE}sparql10/#{partial}/manifest.ttl"
    end
  end

  def self.sparql1_1_tests
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
      csv-tsv-res
      delete-data
      delete-insert
      delete-where
      delete
      drop
      entailment
      exists
      functions
      grouping
      json-res
      move
      negation
      project-expression
      property-path
      service
      subquery
      syntax-query
      syntax-update-1
      syntax-update-2
      update-silent
      syntax-fed
      service-description
      protocol
      http-rdf-update
    ).map do |partial|
      "#{BASE}sparql11/#{partial}/manifest.ttl"
    end
  end

  def self.sparql_star_tests
    %w(syntax/manifest eval/manifest).map do |man|
      "https://w3c.github.io/rdf-star/tests/sparql/#{man}.jsonld"
    end
  end

  def self.sparql_12_tests
    %w(xsd_functions property-path-min-max).map do |partial|
      "https://w3c.github.io/sparql-12/tests/#{partial}/manifest.ttl"
    end
  end
end