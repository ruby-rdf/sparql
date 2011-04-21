require "bundler/setup"
require 'open-uri/cached'
require 'sparql'
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  #config.include(RDF::Spec::Matchers)
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.exclusion_filter = {
    :ruby           => lambda { |version| RUBY_VERSION.to_s !~ /^#{version}/},
  }
end

# Create and maintain a cache of downloaded URIs
URI_CACHE = File.expand_path(File.join(File.dirname(__FILE__), "uri-cache"))
Dir.mkdir(URI_CACHE) unless File.directory?(URI_CACHE)
OpenURI::Cache.class_eval { @cache_path = URI_CACHE }

DAWG = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-dawg#')
MF   = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#')
QT   = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-query#')
RS   = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/result-set#')
