# SPARQL for RDF.rb

This is a [Ruby][] implementation of [SPARQL][] for [RDF.rb][].

[![Gem Version](https://badge.fury.io/rb/sparql.png)](http://badge.fury.io/rb/sparql)

[![Build Status](https://travis-ci.org/ruby-rdf/sparql.png?branch=master)](http://travis-ci.org/ruby-rdf/sparql)

## Features

* 100% free and unencumbered [public domain](http://unlicense.org/) software.
* [SPARQL 1.0][] query parsing and execution
* Limited [SPARQL 1.1][] query parsing and execution
* SPARQL results as [XML][SPARQL XML], [JSON][SPARQL JSON] or HTML.
* SPARQL CONSTRUCT or DESCRIBE serialized based on Format, Extension of Mime Type
  using available RDF Writers (see [Linked Data][])
* SPARQL Client for accessing remote SPARQL endpoints.
* [Rack][] and [Sinatra][] middleware to perform [HTTP content negotiation][conneg] for result formats
  * Compatible with any [Rack][] or [Sinatra][] application and any Rack-based framework.
  * Helper method for describing [SPARQL Service Description][SSD]
* Compatible with Ruby >= 1.9.2.
* Compatible with older Ruby versions with the help of the [Backports][] gem.
* Supports Unicode query strings both on all versions of Ruby.

## Description

The {SPARQL} gem implements the [SPARQL 1.0][] using the [SPARQL 1.1][] grammar,
and provides [Rack][] and [Sinatra][]
middleware to provide results using [HTTP Content Negotiation][conneg].

* {SPARQL::Grammar} implements a [SPARQL 1.1][] parser generating [SPARQL S-Expressions (SSE)][SSE].
  * [SPARQL 1.1][] capabilities beyond [SPARQL 1.0][] are not yet supported.
    See the section on [SPARQL 1.1][] extensions and limitations for further detail.
* {SPARQL::Algebra} executes SSE against Any `RDF::Graph` or `RDF::Repository`, including
  compliant [RDF.rb][] repository adaptors such as [RDF::DO][] and [RDF::Mongo][].
* {Rack::SPARQL} and {Sinatra::SPARQL} provide middleware components to format results
  using an appropriate format based on [HTTP content negotiation][conneg].

### [SPARQL 1.1][] Extensions and Limitations
The {SPARQL} gem uses the [SPARQL 1.1][] {file:etc/sparql11.bnf EBNF grammar}, which provides
much more capability than [SPARQL 1.0][], but has a few limitations:

* The format for decimal datatypes has changed in [RDF 1.1][]; they may no
  longer have a trailing ".", although they do not need a leading digit.
* BNodes may now include extended characters, including ".". As a consequence, BNodes
  used in the object position, where the statement or pattern is terminated by a "."
  must contain whitespace separating the BNode label, and the ".".

The SPARQL gem now implements the following [SPARQL 1.1][] operations:

* Support for all [functions](http://www.w3.org/TR/sparql11-query/#SparqlOps).
* Support for [BIND](http://www.w3.org/TR/sparql11-query/#bind)

### Middleware

`Rack::SPARQL` is a superset of [Rack::LinkedData][] to allow content negotiated results
to be returned any `RDF::Enumerable` or `RDF::Query::Solutions` compatible results.
You would typically return an instance of `RDF::Graph`, `RDF::Repository` or `RDF::Query::Solutions`
from your Rack application, and let the `Rack::SPARQL::ContentNegotiation` middleware
take care of serializing your response into whatever format the HTTP
client requested and understands.

`Sinatra::SPARQL` is a thin Sinatra-specific wrapper around the
{Rack::SPARQL} middleware, which implements SPARQL
 content negotiation for Rack applications.

The middleware queries [RDF.rb][] for the MIME content types of known RDF
serialization formats, so it will work with whatever serialization plugins
that are currently available for RDF.rb. (At present, this includes support
for N-Triples, N-Quads, Turtle, RDF/XML, RDF/JSON, JSON-LD, RDFa, TriG and TriX.)

### Remote datasets

A SPARQL query containing `FROM` or `FROM NAMED` will load the referenced IRI unless the repository
already contains a context with that same IRI. This is performed using [RDF.rb][] `RDF::Util::File.open_file`
passing HTTP Accept headers for various available RDF formats. For best results, require [Linked Data][] to enable
a full set of RDF formats in the `GET` request. Also, consider overriding `RDF::Util::File.open_file` with
an implementation with support for HTTP Get headers (such as `Net::HTTP`).

Queries using datasets are re-written to use the identified graphs for `FROM` and `FROM NAMED` by filtering the results, allowing the use of a repository that contains many graphs without confusing information.

### Result formats

`SPARQL.serialize_results` may be used on it's own, or in conjunction with {Rack::SPARQL} or {Sinatra::SPARQL}
to provide content-negotiated query results. For basic `SELECT` and `ASK` this includes HTML, XML and JSON formats.
`DESCRIBE` and `CONSTRUCT` create an `RDF::Graph`, which can be serialized through [HTTP Content Netogiation][conneg]
using available RDF writers. For best results, require [Linked Data][] to enable
a full set of RDF formats.

## Examples

    require 'rubygems'
    require 'sparql'

### Executing a SPARQL query against a repository

    queryable = RDF::Repository.load("etc/doap.ttl")
    sse = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
    sse.execute(queryable)

### Rendering solutions as JSON, XML or HTML
    queryable = RDF::Repository.load("etc/doap.ttl")
    solutions = SPARQL.execute("SELECT * WHERE { ?s ?p ?o }", queryable)
    solutions.to_json #to_xml #to_html

### Parsing a SPARQL query string to SSE

    sse = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
    sse.to_sxp

### Command line processing

    sparql --default-graph etc/doap.ttl etc/from_default.rq
    sparql -e "SELECT * FROM <etc/doap.ttl> WHERE { ?s ?p ?o }"

    # Generate SPARQL Algebra Expression (SSE) format
    sparql --to-sse etc/input.rq
    sparql --to-sse -e "SELECT * WHERE { ?s ?p ?o }"

    # Run query using SSE input
    sparql --default-graph etc/doap.ttl --sse etc/input.sse
    sparql --sse -e "(dataset (<etc/doap.ttl>) (bgp (triple ?s ?p ?o))))"

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
      graph << [RDF::Node.new, RDF::DC.title, "Hello, world!"]
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
      settings.sparql_options.replace(:standard_prefixes => true)
      repository = RDF::Repository.new do |graph|
        graph << [RDF::Node.new, RDF::DC.title, "Hello, world!"]
      end
      if params["query"]
        query = params["query"].to_s.match(/^http:/) ? RDF::Util::File.open_file(params["query"]) : ::URI.decode(params["query"].to_s)
        SPARQL.execute(query, repository)
      else
        settings.sparql_options.merge!(:prefixes => {
          :ssd => "http://www.w3.org/ns/sparql-service-description#",
          :void => "http://rdfs.org/ns/void#"
        })
        service_description(:repo => repository)
      end
    end

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

* [Ruby](http://ruby-lang.org/) (>= 1.9.2)
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 1.1)
* [SPARQL::Client](https://rubygems.org/gems/sparql-client) (>= 1.0)
* [SXP](https://rubygems.org/gems/sxp) (>= 0.1.0)
* [Builder](https://rubygems.org/gems/builder) (>= 3.0.0)
* [JSON](https://rubygems.org/gems/json) (>= 1.5.1)
* Soft dependency on [Linked Data][] (>= 1.0)
* Soft dependency on [Nokogiri](http://rubygems.org/gems/nokogiri) (>= 1.5.0)
  Falls back to REXML for XML parsing Builder for XML serializing. Nokogiri is much more efficient
* Soft dependency on [Equivalent XML](https://rubygems.org/gems/equivalent-xml) (>= 0.3.0)
  Equivalent XML performs more efficient comparisons of XML Literals when Nokogiri is included
* Soft dependency on [Rack][] (>= 1.4.4)
* Soft dependency on [Sinatra][] (>= 1.3.3)

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

A copy of the [SPARQL 1.0 tests][] and [SPARQL 1.1 tests][] are included in the repository, which are not covered under the UNLICENSE; see the references for test copyright information.

[Ruby]:             http://ruby-lang.org/
[RDF]:              http://www.w3.org/RDF/
[RDF::DO]:          http://rubygems.org/gems/rdf-do
[RDF::Mongo]:       http://rubygems.org/gems/rdf-mongo
[Rack::LinkedData]: http://rubygems.org/gems/rack-linkeddata
[YARD]:             http://yardoc.org/
[YARD-GS]:          http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              http://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
[SPARQL]:           http://en.wikipedia.org/wiki/SPARQL
[SPARQL 1.0]:       http://www.w3.org/TR/rdf-sparql-query/
[SPARQL 1.0 tests]:http://www.w3.org/2001/sw/DataAccess/tests/
[SPARQL 1.1 tests]: http://www.w3.org/2009/sparql/docs/tests/
[SPARQL 1.1]:       http://www.w3.org/TR/sparql11-query/
[SSE]:              http://openjena.org/wiki/SSE
[SXP]:              http://sxp.rubyforge.org/
[grammar]:          http://www.w3.org/TR/rdf-sparql-query/#grammar
[RDF 1.1]:          http://www.w3.org/TR/rdf11-concepts
[RDF.rb]:           http://rdf.rubyforge.org/
[Backports]:        http://rubygems.org/gems/backports
[Linked Data]:      http://rubygems.org/gems/linkeddata
[SPARQL doc]:       http://rubydoc.info/github/ruby-rdf/sparql/frames
[SPARQL XML]:       http://www.w3.org/TR/rdf-sparql-XMLres/
[SPARQL JSON]:      http://www.w3.org/TR/rdf-sparql-json-res/
[SPARQL Protocol]:  http://www.w3.org/TR/rdf-sparql-protocol/
[SSD]:              http://www.w3.org/TR/sparql11-service-description/
[Rack]:             http://rack.rubyforge.org/
[Sinatra]:          http://www.sinatrarb.com/
[conneg]:           http://en.wikipedia.org/wiki/Content_negotiation

