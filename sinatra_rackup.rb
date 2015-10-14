# Sinatra example
#
# Call as http://localhost:4567/sparql?query=uri,
# where `uri` is the URI of a SPARQL query, or
# a URI-escaped SPARQL query, for example:
#   http://localhost:4567/?query=SELECT%20?s%20?p%20?o%20WHERE%20%7B?s%20?p%20?o%7D
require 'sinatra'
require 'sinatra/sparql'
require 'uri'

get '/' do
  settings.sparql_options.merge!(standard_prefixes: true)
  repository = RDF::Repository.new do |graph|
    graph << [RDF::Node.new, RDF::Vocab::DC.title, "Hello, world!"]
  end
  if params["query"]
    query = query.to_s =~ /^\w:/ ? RDF::Util::File.open_file(params["query"]) : :URI.decode(params["query"].to_s)
    SPARQL.execute(query, repository)
  else
    service_description(repo: repository)
  end
end
