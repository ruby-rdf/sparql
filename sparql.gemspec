#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = "sparql"
  gem.homepage           = "http://github.com/ruby-rdf/sparql"
  gem.license            = 'Unlicense'
  gem.summary            = "SPARQL Query and Update library for Ruby."

  gem.authors            = ['Gregg Kellogg', 'Arto Bendiken']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.md UNLICENSE VERSION bin/sparql) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w(sparql)
  gem.require_paths      = %w(lib)
  gem.description        = %(
    Implements SPARQL grammar parsing to SPARQL Algebra, SPARQL Algebra processing
    and includes SPARQL Client for accessing remote repositories.)

  gem.required_ruby_version      = '>= 2.2.2'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',                '~> 3.0'
  #gem.add_runtime_dependency     'rdf-aggregate-repo', '~> 3.0'
  gem.add_runtime_dependency     'rdf-aggregate-repo', '>= 2.2', '< 4.0'
  gem.add_runtime_dependency     'ebnf',               '~> 1.1'
  gem.add_runtime_dependency     'builder',            '~> 3.2'
  gem.add_runtime_dependency     'sxp',                '~> 1.0'
  gem.add_runtime_dependency     'sparql-client',      '~> 3.0'
  gem.add_runtime_dependency     'rdf-xsd',            '~> 3.0'
  gem.add_runtime_dependency     'i18n',               '<= 1.5.1' if RUBY_VERSION < "2.3"

  gem.add_development_dependency 'sinatra',            '~> 2.0'
  gem.add_development_dependency 'rack',               '~> 2.0'
  gem.add_development_dependency 'rack-test',          '~> 0.8'
  gem.add_development_dependency 'rdf-spec',           '~> 3.0'
  gem.add_development_dependency 'linkeddata',         '~> 3.0'
  gem.add_development_dependency 'open-uri-cached',    '~> 0.0', '>= 0.0.5'
  gem.add_development_dependency 'rspec',              '~> 3.7'
  gem.add_development_dependency 'rspec-its',          '~> 1.2'
  gem.add_development_dependency 'yard' ,              '~> 0.9.12'

  gem.post_install_message       = nil
end
