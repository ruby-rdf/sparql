require "bundler/setup"
require 'rspec/its'
require 'yaml'
require 'rspec'
require 'rdf'
require 'rdf/spec'
require 'rdf/isomorphic'
require 'rdf/turtle'
require 'rdf/vocab'
require 'strscan'

begin
  require 'simplecov'
  require 'simplecov-lcov'
  SimpleCov::Formatter::LcovFormatter.config do |config|
    #Coveralls is coverage by default/lcov. Send info results
    config.report_with_single_file = true
    config.single_report_path = 'coverage/lcov.info'
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::LcovFormatter
  ])
  SimpleCov.start do
    add_filter "/spec/"
  end
rescue LoadError => e
  STDERR.puts "Coverage Skipped: #{e.message}"
end

require 'sparql'

Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

RSpec.configure do |rspec|
  #rspec.include(RDF::Spec::Matchers)
  rspec.filter_run focus: true
  rspec.run_all_when_everything_filtered = true
  rspec.expect_with :rspec do |c|
    c.on_potential_false_positives = :nothing
  end
  rspec.exclusion_filter = {
    :ruby           => lambda { |version| RUBY_VERSION.to_s !~ /^#{version}/},
    :blank_nodes    => 'unique',
    :arithmetic     => 'native',
    sparql_algebra: false,
    #:status         => 'bug',
    :reduced        => 'all',
  }
end

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

def load_repo(opts)
  # Load default and named graphs into repository
  case opts[:graphs]
  when RDF::Queryable
    opts[:graphs]
  when Array
    RDF::Repository.new do |r|
      opts[:graphs].each do |info|
        data, format = info[:data], info[:format]
        if data
          RDF::Reader.for(format).new(data, rdfstar: true, **info).each_statement do |st|
            st.graph_name = RDF::URI(info[:base_uri]) if info[:base_uri]
            r << st
          end
        end
      end
    end
  when Hash
    RDF::Repository.new do |r|
      opts[:graphs].each do |key, info|
        next if key == :result
        data, format = info[:data], info[:format]
        if data
          RDF::Reader.for(format).new(data, rdfstar: true, **info).each_statement do |st|
            st.graph_name = RDF::URI(info[:base_uri]) if info[:base_uri]
            r << st
          end
        end
      end
    end
  else
    RDF::Repository.new
  end
end

def sparql_query(opts)
  raise "A query is required to be run" if opts[:query].nil?

  repo = load_repo(opts)

  query_str = opts[:query]
  parser_opts = {
    all_vars: opts[:all_vars],
    base_uri: opts[:base_uri],
    optimize: opts[:optimize],
    update: opts[:form] == :update,
    use11: opts[:use11],
  }
  query_opts = {logger: opts.fetch(:logger, RDF::Spec.logger)}
  query_opts[:base_uri] = opts[:base_uri]

  query = if opts[:sse]
    SPARQL::Algebra.parse(query_str, **parser_opts)
  else
    SPARQL.parse(query_str, **parser_opts)
  end

  repo.query(query, logger: opts.fetch(:logger, RDF::Spec.logger))
end

