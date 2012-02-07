#!/usr/bin/env rackup
# Sinatra rackup example
$:.unshift(File.expand_path('../lib',  __FILE__))
require 'rubygems' || Gem.clear_paths
require 'bundler'
Bundler.setup

require 'sinatra'
require 'sinatra/sparql'

module My
  class Application < Sinatra::Base
    register Sinatra::SPARQL

    get '/' do
      settings.sparql_options.merge!(:standard_prefixes => true)
      repository = RDF::Repository.new do |graph|
        graph << [RDF::Node.new, RDF::DC.title, "Hello, world!"]
      end
      r = SPARQL.execute("SELECT * WHERE { ?s ?p ?o }", repository)
      puts "solutions: #{r.inspect}"
      {:solutions => r}
    end
  end
end

run My::Application
