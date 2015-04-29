$:.unshift File.expand_path("..", __FILE__)
require 'rdf'
require 'psych'
require 'yaml'

# For now, override RDF::Utils::File.open_file to look for the file locally before attempting to retrieve it
module RDF::Util
  module File
    LOCAL_PATH = ::File.expand_path("../dawg", __FILE__) + '/'

    ##
    # Override to use Patron for http and https, Kernel.open otherwise.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    # @option options [Array, String] :headers
    #   HTTP Request headers.
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, options = {}, &block)
      case filename_or_url.to_s
      when /^file:/
        path = filename_or_url[5..-1]
        Kernel.open(path.to_s, &block)
      when %r{^(#{SPARQL::Spec::BASE_URI_10}|#{SPARQL::Spec::BASE_URI_11})}
        begin
          #puts "attempt to open #{filename_or_url} locally"
          local_filename = filename_or_url.to_s.sub($1, LOCAL_PATH)
          if ::File.exist?(local_filename)
            response = ::File.open(local_filename, options)
            #puts "use #{filename_or_url} locally"
            case filename_or_url.to_s
            when /\.ttl$/
              def response.content_type; 'application/turtle'; end
            when /\.nt$/
              def response.content_type; 'application/n-triples'; end
            end

            if block_given?
              begin
                yield response
              ensure
                response.close
              end
            else
              response
            end
          else
            Kernel.open(filename_or_url.to_s, options, &block)
          end
        rescue Errno::ENOENT #, OpenURI::HTTPError
          # Not there, don't run tests
          StringIO.new("")
        end
      else
        Kernel.open(filename_or_url.to_s, options, &block)
      end
    end
  end
end

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
    BASE_DIRECTORY = File.expand_path("../dawg", __FILE__) + "/"
    BASE_URI_10 = RDF::URI("http://www.w3.org/2001/sw/DataAccess/tests/")
    BASE_URI_11 = RDF::URI("http://www.w3.org/2009/sparql/docs/tests/")

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

      if options[:cache_file] && File.exists?(options[:cache_file])
        File.open(options[:cache_file]) do |f|
          YAML.load(f)
        end
      else

        puts "Loading tests from #{manifest_uri}"
        test_repo.load(manifest_uri, options)
        #puts test_repo.dump(:ttl,
        #  :base_uri => BASE_URI,
        #  :prefixes => {
        #    :dawg => DAWGT.to_uri,
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
          
        if options[:save_cache]
          puts "write test cases to #{options[:cache_file]}"
          File.open(options[:cache_file], 'w') do |f|
            YAML.dump(tests, f)
          end
        end
        
        tests
      end
    end

    def self.sparql1_0_tests(save_cache = false)
      self.load_tests(File.join(BASE_URI_10, "data-r2/manifest-evaluation.ttl"),
        :cache_file => File.join(BASE_DIRECTORY, "sparql-specs-1_0-cache.yml"),
        :save_cache => save_cache)
    end

    def self.sparql1_0_syntax_tests(save_cache = false)
      self.load_tests(File.join(BASE_URI_10, "data-r2/manifest-syntax.ttl"),
        :cache_file => File.join(BASE_DIRECTORY, "sparql-specs-1_0_syntax-cache.yml"),
        :save_cache => save_cache)
    end

    def self.sparql1_1_tests(save_cache = false)
      self.load_tests(File.join(BASE_URI_11, "data-sparql11/manifest-all.ttl"),
        :cache_file => File.join(BASE_DIRECTORY, "sparql-specs-1_1_cache.yml"),
        :save_cache => save_cache)
    end
  end # Spec
end # RDF
