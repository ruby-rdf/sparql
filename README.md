# SPARQL for RDF.rb

This is a [Ruby][] implementation of [SPARQL][] for [RDF.rb][].

[![Gem Version](https://badge.fury.io/rb/sparql.png)](http://badge.fury.io/rb/sparql)

[![Build Status](https://travis-ci.org/ruby-rdf/sparql.png?branch=master)](http://travis-ci.org/ruby-rdf/sparql)

[![Coverage Status](https://coveralls.io/repos/ruby-rdf/sparql/badge.svg)](https://coveralls.io/r/ruby-rdf/sparql)

## Features

* 100% free and unencumbered [public domain](http://unlicense.org/) software.
* Complete [SPARQL 1.1 Query][] parsing and execution
* SPARQL results as [XML][SPARQL XML], [JSON][SPARQL JSON],
  [CSV][SPARQL 1.1 Query Results CSV and TSV Formats],
  [TSV][SPARQL 1.1 Query Results CSV and TSV Formats]
  or HTML.
* SPARQL CONSTRUCT or DESCRIBE serialized based on Format, Extension of Mime Type
  using available RDF Writers (see [Linked Data][])
* SPARQL Client for accessing remote SPARQL endpoints.
* SPARQL Update
* [Rack][] and [Sinatra][] middleware to perform [HTTP content negotiation][conneg] for result formats
  * Compatible with any [Rack][] or [Sinatra][] application and any Rack-based framework.
  * Helper method for describing [SPARQL Service Description][SSD]
* Implementation Report: {file:etc/earl.html EARL}
* Compatible with Ruby >= 2.2.2.
* Compatible with older Ruby versions with the help of the [Backports][] gem.
* Supports Unicode query strings both on all versions of Ruby.

## Description

The {SPARQL} gem implements [SPARQL 1.1 Query][], and [SPARQL 1.1 Update][], and provides [Rack][] and [Sinatra][] middleware to provide results using [HTTP Content Negotiation][conneg].

* {SPARQL::Grammar} implements a [SPARQL 1.1 Query][] and [SPARQL 1.1 Update][] parser generating [SPARQL S-Expressions (SSE)][SSE].
* {SPARQL::Algebra} executes SSE against Any `RDF::Graph` or `RDF::Repository`, including compliant [RDF.rb][] repository adaptors such as [RDF::DO][] and [RDF::Mongo][].
* {Rack::SPARQL} and {Sinatra::SPARQL} provide middleware components to format results using an appropriate format based on [HTTP content negotiation][conneg].

### [SPARQL 1.1 Query][] Extensions and Limitations
The {SPARQL} gem uses the [SPARQL 1.1 Query][] {file:etc/sparql11.html EBNF grammar}, which provides much more capability than [SPARQL 1.0][], but has a few limitations:

* The format for decimal datatypes has changed in [RDF 1.1][]; they may no
  longer have a trailing ".", although they do not need a leading digit.
* BNodes may now include extended characters, including ".".

The SPARQL gem now implements the following [SPARQL 1.1 Query][] operations:

* [Functions](http://www.w3.org/TR/sparql11-query/#SparqlOps)
* [BIND](http://www.w3.org/TR/sparql11-query/#bind)
* [GROUP BY](http://www.w3.org/TR/sparql11-query/#groupby)
* [Aggregates](http://www.w3.org/TR/sparql11-query/#aggregates)
* [Subqueries](http://www.w3.org/TR/sparql11-query/#subqueries)
* [Inline Data](http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#inline-data)
* [Inline Data](http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#inline-data)
* [Exists](http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#func-filter-exists)
* [Negation](http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#negation)
* [Property Paths](http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#propertypaths)

The gem also includes the following [SPARQL 1.1 Update][] operations:
* [Graph Update](http://www.w3.org/TR/sparql11-update/#graphUpdate)
* [Graph Management](http://www.w3.org/TR/sparql11-update/#graphManagement)

Not supported:

* [Federated Query][SPARQL 1.1 Federated Query],
* [Entailment Regimes][SPARQL 1.1 Entailment Regimes],
* [Protocol][SPARQL 1.1 Protocol], and
* [Graph Store HTTP Protocol][SPARQL 1.1 Graph Store HTTP Protocol]

either in this, or related gems.

### Updates for RDF 1.1
Starting with version 1.1.2, the SPARQL gem uses the 1.1 version of the [RDF.rb][], which adheres to [RDF 1.1 Concepts](http://www.w3.org/TR/rdf11-concepts/) rather than [RDF 1.0](http://www.w3.org/TR/rdf-concepts/). The main difference is that there is now no difference between a _Simple Literal_ (a literal with no datatype or language) and a Literal with datatype _xsd:string_; this causes some minor differences in the way in which queries are understood, and when expecting different results.

Additionally, queries now take a block, or return an `Enumerator`; this is in keeping with much of the behavior of [RDF.rb][] methods, including `Queryable#query`, and with version 1.1 or [RDF.rb][], Query#execute. As a consequence, all queries which used to be of the form `query.execute(repository)` may equally be called as `repository.query(query)`. Previously, results were returned as a concrete class implementing `RDF::Queryable` or `RDF::Query::Solutions`, these are now `Enumerators`.

### SPARQL Extension Functions
Extension functions may be defined, which will be invoked during query evaluation. For example:

    # Register a function using the IRI <http://rubygems.org/gems/sparql#crypt>
    crypt_iri = RDF::URI("http://rubygems.org/gems/sparql#crypt")
    SPARQL::Algebra::Expression.register_extension(crypt_iri) do |literal|
      raise TypeError, "argument must be a literal" unless literal.literal?
      RDF::Literal(literal.to_s.crypt)
    end

Then, use the function in a query:

    PREFIX rsp: <http://rubygems.org/gems/sparql#>
    PREFIX schema: <http://schema.org/>
    SELECT ?crypted
    {
      [ schema:email ?email]
      BIND(rsp:crypt(?email) AS ?crypted)
    }

See {SPARQL::Algebra::Expression.register_extension} for details.

### Middleware

{Rack::SPARQL} is a superset of [Rack::LinkedData][] to allow content negotiated results
to be returned any `RDF::Enumerable` or an enumerator extended with `RDF::Query::Solutions` compatible results.
You would typically return an instance of `RDF::Graph`, `RDF::Repository` or an enumerator extended with `RDF::Query::Solutions`
from your Rack application, and let the `Rack::SPARQL::ContentNegotiation` middleware
take care of serializing your response into whatever format the HTTP
client requested and understands.

{Sinatra::SPARQL} is a thin Sinatra-specific wrapper around the
{Rack::SPARQL} middleware, which implements SPARQL
 content negotiation for Rack applications. {Sinatra::SPARQL} also supports
 [SPARQL 1.1 Service Description][].

The middleware queries [RDF.rb][] for the MIME content types of known RDF
serialization formats, so it will work with whatever serialization extensions
that are currently available for RDF.rb. (At present, this includes support
for N-Triples, N-Quads, Turtle, RDF/XML, RDF/JSON, JSON-LD, RDFa, TriG and TriX.)

### Remote datasets

A SPARQL query containing `FROM` or `FROM NAMED` (also `UPDATE` or `UPDATE NAMED`) will load the referenced IRI unless the repository already contains a graph with that same IRI. This is performed using [RDF.rb][] `RDF::Util::File.open_file` passing HTTP Accept headers for various available RDF formats. For best results, require [Linked Data][] to enable a full set of RDF formats in the `GET` request. Also, consider overriding `RDF::Util::File.open_file` with an implementation with support for HTTP Get headers (such as `Net::HTTP`).

Queries using datasets are re-written to use the identified graphs for `FROM` and `FROM NAMED` by filtering the results, allowing the use of a repository that contains many graphs without confusing information.

### Result formats

`SPARQL.serialize_results` may be used on it's own, or in conjunction with {Rack::SPARQL} or {Sinatra::SPARQL}
to provide content-negotiated query results. For basic `SELECT` and `ASK` this includes HTML, XML, CSV, TSV and JSON formats.
`DESCRIBE` and `CONSTRUCT` create an `RDF::Graph`, which can be serialized through [HTTP Content Negotiation][conneg]
using available RDF writers. For best results, require [Linked Data][] to enable
a full set of RDF formats.

## Examples

    require 'rubygems'
    require 'sparql'

### Querying a repository with a SPARQL query

    queryable = RDF::Repository.load("etc/doap.ttl")
    sse = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
    queryable.query(sse) do |result|
      result.inspect
    end

### Executing a SPARQL query against a repository

    queryable = RDF::Repository.load("etc/doap.ttl")
    sse = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
    sse.execute(queryable) do |result|
      result.inspect
    end

### Updating a respository

    queryable = RDF::Repository.load("etc/doap.ttl")
    sse = SPARQL.parse(%(
      PREFIX doap: <http://usefulinc.com/ns/doap#>
      INSERT DATA { <http://rubygems.org/gems/sparql> doap:implements <http://www.w3.org/TR/sparql11-update/>}
    ), update: true)
    sse.execute(queryable)

### Rendering solutions as JSON, XML, CSV, TSV or HTML
    queryable = RDF::Repository.load("etc/doap.ttl")
    solutions = SPARQL.execute("SELECT * WHERE { ?s ?p ?o }", queryable)
    solutions.to_json #to_xml #to_csv #to_tsv #to_html

### Parsing a SPARQL query string to SSE

    sse = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
    sse.to_sxp #=> (bgp (triple ?s ?p ?o))

### Command line processing

    sparql execute --dataset etc/doap.ttl etc/from_default.rq
    sparql execute -e "SELECT * FROM <etc/doap.ttl> WHERE { ?s ?p ?o }"

    # Generate SPARQL Algebra Expression (SSE) format
    sparql parse etc/input.rq
    sparql parse -e "SELECT * WHERE { ?s ?p ?o }"

    # Run query using SSE input
    sparql execute --dataset etc/doap.ttl --sse etc/input.sse
    sparql execute --sse -e "(dataset (<etc/doap.ttl>) (bgp (triple ?s ?p ?o))))"

    # Run a local SPARQL server using a dataset
    sparql server etc/doap.ttl

### Adding SPARQL content negotiation to a Rails 3.x application

    # config/application.rb
    require 'rack/sparql'
    
    class Application < Rails::Application
      config.middleware.use Rack::SPARQL::ContentNegotiation
    end

### Adding SPARQL content negotiation to a Rackup application

    #!/usr/bin/env rackup
    require 'rack/sparql'
    
    repository = RDF::Repository.new do |graph|
      graph << [RDF::Node.new, RDF::Vocab::DC.title, "Hello, world!"]
    end
    results = SPARQL.execute("SELECT * WHERE { ?s ?p ?o }", repository)
    
    use Rack::SPARQL::ContentNegotiation
    run lambda { |env| [200, {}, results] }

### Adding SPARQL content negotiation to a classic Sinatra application

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
      settings.sparql_options.replace(standard_prefixes: true)
      repository = RDF::Repository.new do |graph|
        graph << [RDF::Node.new, RDF::Vocab::DC.title, "Hello, world!"]
      end
      if params["query"]
        query = params["query"].to_s.match(/^http:/) ? RDF::Util::File.open_file(params["query"]) : ::URI.decode(params["query"].to_s)
        SPARQL.execute(query, repository)
      else
        settings.sparql_options.merge!(prefixes: {
          ssd: "http://www.w3.org/ns/sparql-service-description#",
          void: "http://rdfs.org/ns/void#"
        })
        service_description(repo: repository)
      end
    end

Find more examples in {SPARQL::Grammar} and {SPARQL::Algebra}.

## Documentation

Full documentation available on [Rubydoc.info][SPARQL doc]

### Principle Classes

* {SPARQL}
  * {SPARQL::Algebra}
    * {SPARQL::Algebra::Expression}
    * {SPARQL::Algebra::Query}
    * {SPARQL::Algebra::Operator}
  * {SPARQL::Grammar}
    * {SPARQL::Grammar::Parser}
* {Sinatra::SPARQL}
* {Rack::SPARQL}
  * {Rack::SPARQL::ContentNegotiation}

## Dependencies

* [Ruby](http://ruby-lang.org/) (>= 1.9.3)
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 1.1.12)
* [SPARQL::Client](https://rubygems.org/gems/sparql-client) (>= 1.1.3)
* [SXP](https://rubygems.org/gems/sxp) (>= 0.1.3)
* [Builder](https://rubygems.org/gems/builder) (>= 3.0.0)
* [JSON](https://rubygems.org/gems/json) (>= 1.8.2)
* Soft dependency on [Linked Data][] (>= 1.1)
* Soft dependency on [Nokogiri](http://rubygems.org/gems/nokogiri) (>= 1.6.6)
  Falls back to REXML for XML parsing Builder for XML serializing. Nokogiri is much more efficient
* Soft dependency on [Equivalent XML](https://rubygems.org/gems/equivalent-xml) (>= 0.3.0)
  Equivalent XML performs more efficient comparisons of XML Literals when Nokogiri is included
* Soft dependency on [Rack][] (>= 1.6.0)
* Soft dependency on [Sinatra][] (>= 1.4.6)

## Installation

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `SPARQL` gem, do:

    % [sudo] gem install sparql

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/sparql.git

## Mailing List

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Authors

* [Gregg Kellogg](http://github.com/gkellogg) - <http://greggkellogg.net/>
* [Arto Bendiken](http://github.com/bendiken) - <http://ar.to/>
* [Pius Uzamere](http://github.com/pius) - <http://pius.me/>

## Contributing
This repository uses [Git Flow](https://github.com/nvie/gitflow) to mange development and release activity. All submissions _must_ be on a feature branch based on the _develop_ branch to ease staging and integration.

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the `.gemspec`, `VERSION` or `AUTHORS` files. If you need to
  change them, do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the corresponding
  list in the the `README`. Alphabetical order applies.
* Do note that in order for us to merge any non-trivial changes (as a rule
  of thumb, additions larger than about 15 lines of code), we need an
  explicit [public domain dedication][PDD] on record from you.

## License

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

A copy of the [SPARQL EBNF][] and derived parser files are included in the repository, which are not covered under the UNLICENSE. These files are covered via the [W3C Document License](http://www.w3.org/Consortium/Legal/2002/copyright-documents-20021231).

A copy of the [SPARQL 1.0 tests][] and [SPARQL 1.1 tests][] are also included in the repository, which are not covered under the UNLICENSE; see the references for test copyright information.

[Ruby]:             http://ruby-lang.org/
[RDF]:              http://www.w3.org/RDF/
[RDF::DO]:          http://rubygems.org/gems/rdf-do
[RDF::Mongo]:       http://rubygems.org/gems/rdf-mongo
[Rack::LinkedData]: http://rubygems.org/gems/rack-linkeddata
[YARD]:             http://yardoc.org/
[YARD-GS]:          http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              http://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
[SPARQL]:           http://en.wikipedia.org/wiki/SPARQL
[SPARQL 1.0]:       http://www.w3.org/TR/sparql11-query/
[SPARQL 1.0 tests]:http://www.w3.org/2001/sw/DataAccess/tests/
[SPARQL 1.1 tests]: http://www.w3.org/2009/sparql/docs/tests/
[SSE]:              http://openjena.org/wiki/SSE
[SXP]:              http://www.rubydoc.info/github/bendiken/sxp-ruby
[grammar]:          http://www.w3.org/TR/sparql11-query/#grammar
[RDF 1.1]:          http://www.w3.org/TR/rdf11-concepts
[RDF.rb]:           http://rubydoc.info/github/ruby-rdf/rdf
[Backports]:        http://rubygems.org/gems/backports
[Linked Data]:      http://rubygems.org/gems/linkeddata
[SPARQL doc]:       http://rubydoc.info/github/ruby-rdf/sparql/frames
[SPARQL XML]:       http://www.w3.org/TR/rdf-sparql-XMLres/
[SPARQL JSON]:      http://www.w3.org/TR/rdf-sparql-json-res/
[SPARQL EBNF]:      http://www.w3.org/TR/sparql11-query/#sparqlGrammar

[SSD]:              http://www.w3.org/TR/sparql11-service-description/
[Rack]:             http://rack.github.io
[Sinatra]:          http://www.sinatrarb.com/
[conneg]:           http://en.wikipedia.org/wiki/Content_negotiation

[SPARQL 1.1 Query]:                             http://www.w3.org/TR/sparql11-query/
[SPARQL 1.1 Update]:                            http://www.w3.org/TR/sparql11-update/
[SPARQL 1.1 Service Description]:               http://www.w3.org/TR/sparql11-service-description/
[SPARQL 1.1 Federated Query]:                   http://www.w3.org/TR/sparql11-federated-query/
[SPARQL 1.1 Query Results JSON Format]:         http://www.w3.org/TR/sparql11-results-json/
[SPARQL 1.1 Query Results CSV and TSV Formats]: http://www.w3.org/TR/sparql11-results-csv-tsv/
[SPARQL Query Results XML Format]:              http://www.w3.org/TR/rdf-sparql-XMLres/
[SPARQL 1.1 Entailment Regimes]:                http://www.w3.org/TR/sparql11-entailment/
[SPARQL 1.1 Protocol]:                          http://www.w3.org/TR/sparql11-protocol/
[SPARQL 1.1 Graph Store HTTP Protocol]:         http://www.w3.org/TR/sparql11-http-rdf-update/

