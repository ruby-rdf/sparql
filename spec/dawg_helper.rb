$:.unshift "."
require 'psych' if RUBY_VERSION >= "1.9"
require 'yaml'

module SPARQL
  require 'support/extensions/inspects'
  require 'support/extensions/isomorphic'
  require 'support/matchers/solutions'
  require 'support/models'

  ##
  # `SPARQL::Spec` provides access to the Data Access Working Group (DAWG) test sute for SPARQL.
  #
  # @author [Arto Bendiken](http://ar.to/)
  # @author [Ben Lavender](http://bhuga.net/)
  # @author [Gregg Kellogg](http://greggkellogg.net/)
  module Spec
    BASE_DIRECTORY = File.join(File.expand_path(File.dirname(__FILE__)), 'dawg/')
    BASE_URI = RDF::URI("http://www.w3.org/2001/sw/DataAccess/tests/");

    # Module functions
    
    ##
    # Load tests from the specified file/uri.
    # @param [String] manifest_uri
    # @param [Hash<Symbol => Object>] options
    # @option options [String] :cache_file (nil)
    #   Attempt to load parsed tests from YAML file
    # @option options [String] :save_cache (false)
    #   Save parsed tests in cache_file
    # @return [Array<SPARQL::Spec::SPARQLTest>]
    def self.load_tests(manifest_uri, options = {})
      require 'spira'
      options[:base_uri] ||= manifest_uri

      test_repo = RDF::Repository.new
      Spira.add_repository(:default, test_repo)

      if options[:cache_file] && File.exists?(options[:cache_file]) && RUBY_VERSION >= "1.9"
        File.open(options[:cache_file]) do |f|
          YAML.load(f)
        end
      else

        puts "Loading tests from #{manifest_uri}"
        test_repo.load(manifest_uri, options)
        #puts test_repo.dump(:ttl,
        #  :base_uri => BASE_URI,
        #  :prefixes => {
        #    :dawg => DAWG.to_uri,
        #    :mf => MF.to_uri,
        #    :qt => QT.to_uri,
        #    :rs => RS.to_uri,
        #  }
        #)
        Manifest.each { |manifest| manifest.include_files! }
        tests = Manifest.each.map { |m| m.entries }.flatten.find_all { |t| t.approved? }
        tests.each { |test|
          test.tags << 'status:unverified'
          test.tags << 'w3c_status:unapproved' unless test.approved?
          test.update!(:manifest => test.data.each_context.first)
        }
          
        if options[:save_cache] && RUBY_VERSION >= "1.9"
          #if Kernel.const_defined?(:Psych)
            puts "write test cases to #{options[:cache_file]}"
            File.open(options[:cache_file], 'w') do |f|
              YAML.dump(tests, f)
            end
          #else
          #  puts "saving cached test-cases requires Ruby 1.9 for Psych"
          #end
        end
        
        tests
      end
    end

    def self.sparql1_0_tests(save_cache = false)
      self.load_tests(File.join(BASE_URI, "data-r2/manifest-evaluation.ttl"),
        :cache_file => File.join(BASE_DIRECTORY, "sparql-specs-1_0-cache.yml"),
        :save_cache => save_cache)
    end

    def self.sparql1_0_syntax_tests(save_cache = false)
      self.load_tests(File.join(BASE_URI, "data-r2/manifest-syntax.ttl"),
        :cache_file => File.join(BASE_DIRECTORY, "sparql-specs-1_0_syntax-cache.yml"),
        :save_cache => save_cache)
    end

    def self.sparql1_1_tests(save_cache = false)
      self.load_tests(File.join(BASE_URI, "sparql11-tests/manifest-all.ttl"),
        :cache_file => File.join(BASE_DIRECTORY, "sparql-specs-1_1_cache.yml"),
        :save_cache => save_cache)
    end
  end # Spec
end # RDF
