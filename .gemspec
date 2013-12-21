#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

begin
  RUBY_ENGINE
rescue NameError
  RUBY_ENGINE = "ruby"  # Not defined in Ruby 1.8.7
end

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = "sparql"
  gem.homepage           = "http://github.com/ruby-rdf/sparql"
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = "SPARQL library for Ruby."
  gem.rubyforge_project  = 'sparql'

  gem.authors            = ['Gregg Kellogg', 'Arto Bendiken']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.md UNLICENSE VERSION bin/sparql) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w(sparql)
  gem.default_executable = gem.executables.first
  gem.require_paths      = %w(lib)
  gem.extensions         = %w()
  gem.test_files         = %w()
  gem.has_rdoc           = false
  gem.description        = %(
    Implements SPARQL grammar parsing to SPARQL Algebra, SPARQL Algebra processing
    and includes SPARQL Client for accessing remote repositories.)

  gem.required_ruby_version      = '>= 1.9.2'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',                '>= 1.1.0'
  gem.add_runtime_dependency     'rdf-aggregate-repo', '>= 1.1.0'
  gem.add_runtime_dependency     'ebnf',               '>= 0.3.3'
  gem.add_runtime_dependency     'builder',            '>= 3.0'
  gem.add_runtime_dependency     'json',               '>= 1.7'
  gem.add_runtime_dependency     'sxp',                '>= 0.1.3'
  gem.add_runtime_dependency     'sparql-client',      '>= 1.1'
  gem.add_runtime_dependency     'rdf-xsd',            '>= 1.0.2'

  gem.add_development_dependency 'sinatra',            '>= 1.4.4'
  gem.add_development_dependency 'rack',               '>= 1.5.2'
  gem.add_development_dependency 'rack-test',          '>= 0.6.2'
  gem.add_development_dependency 'linkeddata',         '>= 1.1'
  gem.add_development_dependency 'rdf-spec',           '>= 1.1'
  gem.add_development_dependency 'open-uri-cached',    '>= 0.0.5'
  gem.add_development_dependency 'rspec',              '>= 2.14.0'
  gem.add_development_dependency 'spira',              '= 0.0.12'
  gem.add_development_dependency 'yard' ,              '>= 0.8.3'

  # Rubinius has it's own dependencies
  if RUBY_ENGINE == "rbx" && RUBY_VERSION >= "2.1.0"
    gem.add_runtime_dependency     "rubysl-csv"
    gem.add_runtime_dependency     "rubysl-base64"
    gem.add_runtime_dependency     "rubysl-bigdecimal"
    gem.add_runtime_dependency     "rubysl-getoptlong"
    gem.add_runtime_dependency     "rubysl-rational"
    gem.add_runtime_dependency     "rubysl-rexml"
    gem.add_runtime_dependency     "rubysl-yaml"
    gem.add_runtime_dependency     "racc"

    gem.add_development_dependency "psych"
    gem.add_development_dependency "rubysl-open-uri"
    gem.add_development_dependency "rubysl-prettyprint"
  end

  gem.post_install_message       = nil
end
