require "bundler/setup"
require 'psych'
require 'rubygems'
require 'rspec'
require 'yaml'
require 'open-uri/cached'
require 'rdf'
require 'rdf/isomorphic'
require 'sparql'
require 'rdf/turtle'
require 'rdf/n3'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  #config.include(RDF::Spec::Matchers)
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.exclusion_filter = {
    :ruby           => lambda { |version| RUBY_VERSION.to_s !~ /^#{version}/},
    :blank_nodes    => 'unique',
    :arithmetic     => 'native',
    :sparql_algebra => false,
    #:status         => 'bug',
    :reduced        => 'all',
  }
end

# Create and maintain a cache of downloaded URIs
URI_CACHE = File.expand_path(File.join(File.dirname(__FILE__), "uri-cache"))
Dir.mkdir(URI_CACHE) unless File.directory?(URI_CACHE)
OpenURI::Cache.class_eval { @cache_path = URI_CACHE }

DAWGT = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-dawg#')
ENT   = RDF::Vocabulary.new('http://www.w3.org/ns/entailment/RDF')
MF    = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#')
QT    = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-query#')
RS    = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/result-set#')
UT    = RDF::Vocabulary.new('http://www.w3.org/2009/sparql/tests/test-update#')

def repr(term)
  case term
    when RDF::Node
      "RDF::Node(#{term.to_sym.inspect})"
    when RDF::URI
      "RDF::URI(#{term.to_s.inspect})"
    when RDF::Literal then case
      when term.simple?
        "RDF::Literal(#{term.to_s.inspect})"
      when term.has_language?
        "RDF::Literal(#{term.to_s.inspect}@#{term.language})"
      when term.datatype.eql?(RDF::XSD.string)
        "RDF::Literal::String(#{term.to_s.inspect})"
      when term.is_a?(RDF::Literal::Token)
        "RDF::Literal::Token(#{term.to_s.inspect})"
      when term.is_a?(RDF::Literal::Boolean)
        "RDF::Literal::#{term.true? ? 'TRUE' : 'FALSE'}"
      when term.datatype.eql?(RDF::XSD.float)
        "RDF::Literal::Float(#{term.to_f.inspect})"
      when term.is_a?(RDF::Literal::Numeric)
        value = case term
          when RDF::Literal::Double  then term.to_f.inspect
          when RDF::Literal::Decimal then "BigDecimal(#{term.to_f.inspect})"
          when RDF::Literal::Integer then term.to_i.inspect
          else term.datatype.inspect
        end
        "RDF::Literal(#{value})"
      when term.is_a?(RDF::Literal::DateTime)
        "RDF::Literal::DateTime(#{term.to_s.inspect})"
      else term.inspect
    end
    else term.inspect
  end
end

def sparql_query(opts)
  opts[:to_hash] = true unless opts.has_key?(:to_hash)
  raise "A query is required to be run" if opts[:query].nil?

  # Load default and named graphs into repository
  repo = RDF::Repository.new do |r|
    opts[:graphs].each do |key, info|
      next if key == :result
      data, format, default = info[:data], info[:format], info[:default]
      if data
        RDF::Reader.for(format).new(data, info).each_statement do |st|
          st.context = key unless key == :default || default
          r << st
        end
      end
    end
  end

  query_str = opts[:query]
  query_opts = {:debug => opts[:debug] || !!ENV['PARSER_DEBUG']}
  query_opts[:base_uri] = opts[:base_uri]
  
  query = if opts[:sse]
    SPARQL::Algebra.parse(query_str, query_opts)
  else
    query_opts[:progress] = opts.delete(:progress)
    SPARQL.parse(query_str, query_opts)
  end

  case opts[:form]
  when :ask, :describe, :construct
    repo.query(query, :debug => opts[:debug] || !!ENV['EXEC_DEBUG'])
  else
    results = repo.query(query, :debug => opts[:debug] || !!ENV['EXEC_DEBUG'])
    opts[:to_hash] ? results.map(&:to_hash) : results
  end
end
