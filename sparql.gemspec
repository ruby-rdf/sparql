#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = "sparql"
  gem.homepage           = "https://github.com/ruby-rdf/sparql"
  gem.license            = 'Unlicense'
  gem.summary            = "SPARQL Query and Update library for Ruby."
  gem.description        = %(SPARQL Implements SPARQL 1.1 Query, Update and result formats for the Ruby RDF.rb library suite.)
  gem.metadata           = {
    "documentation_uri" => "https://ruby-rdf.github.io/sparql",
    "bug_tracker_uri"   => "https://github.com/ruby-rdf/sparql/issues",
    "homepage_uri"      => "https://github.com/ruby-rdf/sparql",
    "mailing_list_uri"  => "https://lists.w3.org/Archives/Public/public-rdf-ruby/",
    "source_code_uri"   => "https://github.com/ruby-rdf/sparql",
  }

  gem.authors            = ['Gregg Kellogg', 'Arto Bendiken']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.md UNLICENSE VERSION bin/sparql) + Dir.glob('lib/**/*.rb')
  gem.bindir             = %q(bin)
  gem.executables        = %w(sparql)
  gem.require_paths      = %w(lib)

  gem.required_ruby_version      = '>= 2.6'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',                '~> 3.2', '>= 3.2.8'
  gem.add_runtime_dependency     'rdf-aggregate-repo', '~> 3.2'
  gem.add_runtime_dependency     'ebnf',               '~> 2.2', '>= 2.3.1'
  gem.add_runtime_dependency     'builder',            '~> 3.2'
  gem.add_runtime_dependency     'logger',             '~> 1.5'
  gem.add_runtime_dependency     'sxp',                '~> 1.2', '>= 1.2.2'
  gem.add_runtime_dependency     'sparql-client',      '~> 3.2', '>= 3.2.1'
  gem.add_runtime_dependency     'rdf-xsd',            '~> 3.2'

  gem.add_development_dependency 'sinatra',            '>= 2.2', '< 4'
  gem.add_development_dependency 'rack',               '>= 2.2', '< 4'
  gem.add_development_dependency 'rack-test',          '>= 1.1', '< 3'
  gem.add_development_dependency 'rdf-spec',           '~> 3.2'
  gem.add_development_dependency 'linkeddata',         '~> 3.2'
  gem.add_development_dependency 'rspec',              '~> 3.12'
  gem.add_development_dependency 'rspec-its',          '~> 1.3'
  gem.add_development_dependency 'yard' ,              '~> 0.9'

  gem.post_install_message       = nil
end
