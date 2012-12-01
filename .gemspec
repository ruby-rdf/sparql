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

  gem.authors            = ['Gregg Kellogg', 'Arto Bendiken', 'Pius Uzamere']
  gem.email              = 'public-rdf-ruby@w3.org'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(AUTHORS CREDITS README.markdown UNLICENSE VERSION bin/sparql) + Dir.glob('lib/**/*.rb')
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

  gem.required_ruby_version      = '>= 1.8.7'
  gem.requirements               = []
  gem.add_runtime_dependency     'rdf',             '>= 0.3.5'
  gem.add_runtime_dependency     'builder',         '>= 3.0.0'
  gem.add_runtime_dependency     'json',            '>= 1.5.1'
  gem.add_runtime_dependency     'sxp',             '>= 0.0.14'
  gem.add_runtime_dependency     'sparql-client',   '>= 0.1.0'
  gem.add_runtime_dependency     'rdf-xsd',         '>= 0.3.5'

  gem.add_development_dependency 'sinatra',         '>= 1.3.2'
  gem.add_development_dependency 'rack',            '>= 1.4.1'
  gem.add_development_dependency 'rack-test',       '>= 0.6.1'
  gem.add_development_dependency 'linkeddata',      '>= 0.3.5'
  gem.add_development_dependency 'rdf-spec',        '>= 0.3.5'
  gem.add_development_dependency 'open-uri-cached', '>= 0.0.4'
  gem.add_development_dependency 'equivalent-xml',  '>= 0.2.8'
  gem.add_development_dependency 'nokogiri' ,       '>= 1.5.0'
  gem.add_development_dependency 'rspec',           '>= 2.10.0'
  gem.add_development_dependency 'spira',           '>= 0.0.12'
  gem.add_development_dependency 'yard' ,           '>= 0.8.2'
  gem.add_runtime_dependency     'backports'                    if RUBY_VERSION < "1.9"
  gem.post_install_message       = nil
end