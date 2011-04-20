##
# A SPARQL for RDF.rb.
#
# @see http://www.w3.org/TR/rdf-sparql-query
module SPARQL
  # @see http://rubygems.org/gems/sparql-algebra
  autoload :Algebra, 'sparql/algebra'
  # @see http://rubygems.org/gems/sparql-grammar
  autoload :Grammar, 'sparql/grammar'
  # @see http://rubygems.org/gems/sparql-client
  autoload :Client,  'sparql/client'
  autoload :Results,  'sparql/results'

  ##
  # Parse the given SPARQL `query` string.
  #
  # @example
  #   parser = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
  #   result = parser.parse
  #
  # @param  [IO, StringIO, String, #to_s]  query
  # @param  [Hash{Symbol => Object}] options
  # @return [Parser]
  # @raise  [Parser::Error] on invalid input
  def self.parse(query, options = {}, &block)
    Grammar::Parser.new(query, options).parse
  end

  ##
  # Parse and execute the given SPARQL `query` string against `queriable`.
  #
  # Requires a repository, into which the dataset will be loaded.
  #
  # Optionally takes a list of URIs to load as default or named graphs
  # into the repository
  #
  # @example
  #   repository = RDF::Repository.new
  #   results = SPARQL.execute("SELECT * WHERE { ?s ?p ?o }", repository)
  #   result = parser.parse
  #
  # @param  [IO, StringIO, String, #to_s]  query
  # @param  [RDF::Repository]  repository
  # @param  [Hash{Symbol => Object}] options
  # @return [RDF::Query::Solutions]
  # @raise  [SPARQL::Grammar::Parser::Error] on invalid input
  def self.execute(query, repository, options = {}, &block)
    parser = Grammar::Parser.new(query, options)
    query = parser.parse
    query.execute(repository)
  end
end
