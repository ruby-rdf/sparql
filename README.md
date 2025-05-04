# SPARQL Query and Update library for Ruby

An implementation of [SPARQL][] for [RDF.rb][].

[![Gem Version](https://badge.fury.io/rb/sparql.svg)](https://badge.fury.io/rb/sparql)
[![Build Status](https://github.com/ruby-rdf/sparql/workflows/CI/badge.svg?branch=develop)](https://github.com/ruby-rdf/sparql/actions?query=workflow%3ACI)
[![Coverage Status](https://coveralls.io/repos/ruby-rdf/sparql/badge.svg?branch=develop)](https://coveralls.io/r/ruby-rdf/sparql?branch=develop)
[![Gitter chat](https://badges.gitter.im/ruby-rdf/rdf.png)](https://gitter.im/ruby-rdf/rdf)

## Features

* 100% free and unencumbered [public domain](https://unlicense.org/) software.
* Complete [SPARQL 1.1 Query][] parsing and execution
* SPARQL results as [XML][SPARQL XML], [JSON][SPARQL JSON],
  [CSV][SPARQL 1.1 Query Results CSV and TSV Formats],
  [TSV][SPARQL 1.1 Query Results CSV and TSV Formats]
  or HTML.
* SPARQL CONSTRUCT or DESCRIBE serialized based on Format, Extension of Mime Type
  using available RDF Writers (see [Linked Data][])
* SPARQL Client for accessing remote SPARQL endpoints (via [sparql-client](https://github.com/ruby-rdf/sparql-client)).
* [SPARQL 1.1 Protocol][] (via {SPARQL::Server}).
* [SPARQL 1.1 Update][]
* [Rack][] and [Sinatra][] middleware to perform [HTTP content negotiation][conneg] for result formats
  * Compatible with any [Rack][] or [Sinatra][] application and any Rack-based framework.
  * Helper method for describing [SPARQL Service Description][SSD]
  * Helper method for setting up datasets as part of the [SPARQL 1.1 Protocol][].
* Implementation Report: {file:etc/earl.html EARL}
* Compatible with Ruby >= 3.0.
* Supports Unicode query strings both on all versions of Ruby.
* Provisional support for [SPARQL 1.2][].

## Description

The {SPARQL} gem implements [SPARQL 1.1 Query][], and [SPARQL 1.1 Update][], and provides [Rack][] and [Sinatra][] middleware to provide results using [HTTP Content Negotiation][conneg] and to support [SPARQL 1.1 Protocol][].

* {SPARQL::Grammar} implements a [SPARQL 1.1 Query][] and [SPARQL 1.1 Update][] parser generating [SPARQL S-Expressions (SSE)][SSE].
* {SPARQL::Algebra} executes SSE against Any `RDF::Graph` or `RDF::Repository`, including compliant [RDF.rb][] repository adaptors such as [RDF::DO][] and [RDF::Mongo][].
* {Rack::SPARQL} and {Sinatra::SPARQL} provide middleware components to format results using an appropriate format based on [HTTP content negotiation][conneg].
* {SPARQL::Server} implements the [SPARQL 1.1 Protocol][] using {Sinatra::SPARQL}.

### [SPARQL 1.1 Query][] Extensions and Limitations
The {SPARQL} gem uses the [SPARQL 1.1 Query][] {file:etc/sparql11.html EBNF grammar}, which provides much more capability than [SPARQL 1.0][], but has a few limitations:

* The format for decimal datatypes has changed in [RDF 1.1][]; they may no
  longer have a trailing ".", although they do not need a leading digit.
* BNodes may now include extended characters, including ".".

The SPARQL gem now implements the following [SPARQL 1.1 Query][] operations:

* [Functions](https://www.w3.org/TR/sparql11-query/#SparqlOps)
* [BIND](https://www.w3.org/TR/sparql11-query/#bind)
* [GROUP BY](https://www.w3.org/TR/sparql11-query/#groupby)
* [Aggregates](https://www.w3.org/TR/sparql11-query/#aggregates)
* [Subqueries](https://www.w3.org/TR/sparql11-query/#subqueries)
* [Inline Data](https://www.w3.org/TR/2013/REC-sparql11-query-20130321/#inline-data)
* [Inline Data](https://www.w3.org/TR/2013/REC-sparql11-query-20130321/#inline-data)
* [Exists](https://www.w3.org/TR/2013/REC-sparql11-query-20130321/#func-filter-exists)
* [Negation](https://www.w3.org/TR/2013/REC-sparql11-query-20130321/#negation)
* [Property Paths](https://www.w3.org/TR/2013/REC-sparql11-query-20130321/#propertypaths)

The gem also includes the following [SPARQL 1.1 Update][] operations:
* [Graph Update](https://www.w3.org/TR/sparql11-update/#graphUpdate)
* [Graph Management](https://www.w3.org/TR/sparql11-update/#graphManagement)

Not supported:

* [Federated Query][SPARQL 1.1 Federated Query],
* [Entailment Regimes][SPARQL 1.1 Entailment Regimes], and
* [Graph Store HTTP Protocol][SPARQL 1.1 Graph Store HTTP Protocol] but the closely related [Linked Data Platform][] implemented in [rdf-ldp](https://github.com/ruby-rdf/rdf-ldp) supports these use cases.

### Optimizations
Generally, optimizing a query can lead to improved performance, sometimes dramatically (e.g., `?s rdf:rest*/rdf:first ?o`). Optimization can be done when parsing a query using the `:optimize` option, or the `optimize` method on a parsed query.

### Updates for RDF 1.1
Starting with version 1.1.2, the SPARQL gem uses the 1.1 version of the [RDF.rb][], which adheres to [RDF 1.1 Concepts](https://www.w3.org/TR/rdf11-concepts/) rather than [RDF 1.0](https://www.w3.org/TR/rdf-concepts/). The main difference is that there is now no difference between a _Simple Literal_ (a literal with no datatype or language) and a Literal with datatype _xsd:string_; this causes some minor differences in the way in which queries are understood, and when expecting different results.

Additionally, queries now take a block, or return an `Enumerator`; this is in keeping with much of the behavior of [RDF.rb][] methods, including `Queryable#query`, and with version 1.1 or [RDF.rb][], Query#execute. As a consequence, all queries which used to be of the form `query.execute(repository)` may equally be called as `repository.query(query)`. Previously, results were returned as a concrete class implementing `RDF::Queryable` or `RDF::Query::Solutions`, these are now `Enumerators`.

### SPARQL Dev
The gem supports some of the extensions proposed by the [SPARQL Dev Community Group](https://github.com/w3c/sparql-dev). In particular, the following extensions are now implemented:

* [SEP-0002: better support for Durations, Dates, and Times](https://github.com/w3c/sparql-dev/blob/main/SEP/SEP-0002/sep-0002.md)
  * This includes full support for `xsd:date`, `xsd:time`, `xsd:duration`, `xsd:dayTimeDuration`, and `xsd:yearMonthDuration` along with associated XPath/XQuery functions including a new `ADJUST` builtin. (**Note: This feature is subject to change or elimination as the standards process progresses.**)
* [SEP-0003: Property paths with a min/max hop](https://github.com/w3c/sparql-dev/blob/main/SEP/SEP-0003/sep-0003.md)
  * This includes support for non-counting path forms such as `rdf:rest{1,3}` to match the union of paths `rdf:rest`, `rdf:rest/rdf:rest`, and `rdf:rest/rdf:rest/rdf:rest`.  (**Note: This feature is subject to change or elimination as the standards process progresses.**)

### SPARQL Extension Functions
Extension functions may be defined, which will be invoked during query evaluation. For example:

    # Register a function using the IRI <https://rubygems#crypt>
    crypt_iri = RDF::URI("https://rubygems#crypt")
    SPARQL::Algebra::Expression.register_extension(crypt_iri) do |literal|
      raise TypeError, "argument must be a literal" unless literal.literal?
      RDF::Literal(literal.to_s.crypt)
    end

Then, use the function in a query:

    PREFIX rsp: <https://rubygems#>
    PREFIX schema: <http://schema.org/>
    SELECT ?crypted
    {
      [ schema:email ?email]
      BIND(rsp:crypt(?email) AS ?crypted)
    }

See {SPARQL::Algebra::Expression.register_extension} for details.

### Variable Pre-binding

A call to execute a parsed query can include pre-bound variables, which cause queries to be executed with matching variables bound as defined. Variable pre-binding can be done using a Hash structure, or a Query Solution.  See [Query with Binding example](#query-with-binding) and {SPARQL::Algebra::Query#execute}.

### SPARQL 1.2

The gem supports [SPARQL 1.2][] where patterns may include sub-patterns recursively, for a kind of Reification.

For example, the following Turtle* file uses a statement as the subject of another statement:

    @prefix : <http://bigdata.com/> .
    @prefix foaf: <http://xmlns.com/foaf/0.1/> .
    @prefix ex:  <http://example.org/> .

    :bob foaf:name "Bob" .
    <<:bob foaf:age 23>> ex:certainty 0.9 .

This can be queried using the following query:

    PREFIX : <http://bigdata.com/>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX ex:  <http://example.org/>

    SELECT ?age ?c WHERE {
       ?bob foaf:name "Bob" .
       <<?bob foaf:age ?age>> ex:certainty ?c .
    }

This treats `<<:bob foaf:age 23>>` as a subject resource, and the pattern `<<?bob foaf:age ?age>>` to match that resource and bind the associated variables.

**Note: This feature is subject to change or elimination as the standards process progresses.**

#### BIND

There is an alternate syntax using the `BIND` operator:

    PREFIX : <http://bigdata.com>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX dct:  <http://purl.org/dc/elements/1.1/>

    SELECT ?a ?b ?c WHERE {
       ?bob foaf:name "Bob" .
       BIND( <<?bob foaf:age ?age>> AS ?a ) .
       ?t ?b ?c .
    }

When binding, the triple can be either in Property Graph (`:PG`) or Separate Assertions (`:SA`) mode, as the query matches based on the pattern matching as a subject (or object) and does not need to be specifically asserted in the graph. When parsing in Property Graph mode, such triples will also be added to the enclosing graph. Thus, querying for `<<?bob foaf:age ?age>>` and `?bob foaf:age ?age` may not represent the same results.

When binding an embedded triple to a variable, it is the matched triples which are bound, not the pattern. Thus, the example above with `SELECT ?a ?b ?c` would end up binding `?a` to `:bob foaf:name 23`.

#### Construct

As well as a `CONSTRUCT`:

    PREFIX : <http://bigdata.com>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX dct:  <http://purl.org/dc/elements/1.1/>

    CONSTRUCT {
      ?bob foaf:name "Bob" .
      <<?bob foaf:age ?age>> ?b ?c .
    }
    WHERE {
      ?bob foaf:name "Bob" .
      <<?bob foaf:age ?age>> ?b ?c .
    }

Note that results can be serialized only when the format supports [SPARQL 1,2][].

#### SPARQL results

The SPARQL results formats are extended to serialize quoted triples as described for [RDF4J](https://rdf4j.org/documentation/programming/rdfstar/):

    {
      "head" : {
        "vars" : ["a", "b", "c"]
      },
      "results" : {
        "bindings": [
          { "a" : {
              "type" : "triple",
              "value" : {
                "s" : {"value" : "http://example.org/bob", "type": "uri"},
                "p" : {"value" : "http://xmlns.com/foaf/0.1/name", "type": "uri"},
                "o" : {
                  "value" : "23",
                  "type" : "literal",
                  "datatype" : "http://www.w3.org/2001/XMLSchema#integer"
                }
              }
            },
            "b": {"value": "http://example.org/certainty", "type": "uri"},
            "c" : {
              "value" : "0.9",
              "type" : "literal",
              "datatype" : "http://www.w3.org/2001/XMLSchema#decimal"
            }
          }
        ]
      }
    }

### Middleware

{Rack::SPARQL} is a superset of [Rack::LinkedData][] to allow content negotiated results
to be returned any `RDF::Enumerable` or an enumerator extended with `RDF::Query::Solutions` compatible results.
You would typically return an instance of `RDF::Graph`, `RDF::Repository` or an enumerator extended with `RDF::Query::Solutions`
from your Rack application, and let the `Rack::SPARQL::ContentNegotiation` middleware
take care of serializing your response into whatever format the HTTP
client requested and understands.
Content negotiation also transforms `application/x-www-form-urlencoded` to either `application/sparql-query`
or `application/sparql-update` as appropriate for [SPARQL 1.1 Protocol][].

{Sinatra::SPARQL} is a thin Sinatra-specific wrapper around the
{Rack::SPARQL} middleware, which implements SPARQL
 content negotiation for Rack applications. {Sinatra::SPARQL} also supports
 [SPARQL 1.1 Service Description][] (via {Sinatra::SPARQL::Helpers.service_description} and protocol-based dataset mangement via {Sinatra::SPARQL::Helpers.dataset} for `default-graph-uri` and `named-graph-uri` The `using-graph-uri` and `using-named-graph-uri` query parameters are managed through {SPARQL::Algebra::Operator::Modify#execute}.

The middleware queries [RDF.rb][] for the MIME content types of known RDF
serialization formats, so it will work with whatever serialization extensions
that are currently available for RDF.rb. (At present, this includes support
for N-Triples, N-Quads, Turtle, RDF/XML, RDF/JSON, JSON-LD, RDFa, TriG and TriX.)

### Server

A simple [Sinatra][]-based server is implemented in {SPARQL::Server.application} using {Rack::SPARQL} and {Sinatra::SPARQL} completes the implementation of [SPARQL 1.1 Protocol][] and can be used to compose a server including other capabilities.

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
    query = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
    queryable.query(query) do |result|
      result.inspect
    end

### Executing a SPARQL query against a repository

    queryable = RDF::Repository.load("etc/doap.ttl")
    query = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
    query.execute(queryable) do |result|
      result.inspect
    end

### Updating a repository

    queryable = RDF::Repository.load("etc/doap.ttl")
    update = SPARQL.parse(%(
      PREFIX doap: <http://usefulinc.com/ns/doap#>
      INSERT DATA { <https://rubygems> doap:implements <http://www.w3.org/TR/sparql11-update/>}
    ), update: true)
    update.execute(queryable)

### Rendering solutions as JSON, XML, CSV, TSV or HTML
    queryable = RDF::Repository.load("etc/doap.ttl")
    solutions = SPARQL.execute("SELECT * WHERE { ?s ?p ?o }", queryable)
    solutions.to_json #to_xml #to_csv #to_tsv #to_html

### Parsing a SPARQL query string to SSE

    query = SPARQL.parse("SELECT * WHERE { ?s ?p ?o }")
    query.to_sxp #=> (bgp (triple ?s ?p ?o))

### Parsing a SSE to SPARQL query or update string to SPARQL

    # Note: if the SSE uses extension functions, they either must be XSD casting functions, or custom functions which are registered extensions. (See [SPARQL Extension Functions](#sparql-extension-functions))

    query = SPARQL::Algebra.parse(%{(bgp (triple ?s ?p ?o))})
    sparql = query.to_sparql #=> "SELECT * WHERE { ?s ?p ?o }"

### Query with Binding

    bindings = {page: RDF::URI("https://greggkellogg.net/")}
    queryable = RDF::Repository.load("etc/doap.ttl")
    query = SPARQL.parse(%(
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      SELECT ?person
      WHERE {
        ?person foaf:homepage ?page .
      }
    ))
    solutions = query.execute(queryable, bindings: bindings)
    solutions.to_sxp #=> (((person <https://greggkellogg.net/foaf#me>)))

### Command line processing

    sparql execute --dataset etc/doap.ttl etc/from_default.rq
    sparql execute --dataset etc/doap.ttl -e "SELECT * FROM <etc/doap.ttl> WHERE { ?s ?p ?o }"

    # Generate SPARQL Algebra Expression (SSE) format
    sparql parse etc/input.rq
    sparql parse -e "SELECT * WHERE { ?s ?p ?o }"

    # Generate SPARQL Query from SSE
    sparql parse --sse etc/input.sse --format sparql
    sparql parse --sse --format sparql -e "(dataset (<etc/doap.ttl>) (bgp (triple ?s ?p ?o))))"

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

## Change Log

See [Release Notes on GitHub](https://github.com/ruby-rdf/sparql/releases)

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

* [Ruby](https://ruby-lang.org/) (>= 3.0)
* [RDF.rb](https://rubygems.org/gems/rdf) (~> 3.3)
* [SPARQL::Client](https://rubygems.org/gems/sparql-client) (~> 3.3)
* [SXP](https://rubygems.org/gems/sxp) (~> 2.0)
* [Builder](https://rubygems.org/gems/builder) (~> 3.2)
* [JSON](https://rubygems.org/gems/json) (~> 2.6)
* Soft dependency on [Linked Data][] (>= 3.3)
* Soft dependency on [Nokogiri](https://rubygems.org/gems/nokogiri) (~> 1.15)
  Falls back to REXML for XML parsing Builder for XML serializing. Nokogiri is much more efficient
* Soft dependency on [Equivalent XML](https://rubygems.org/gems/equivalent-xml) (>= 0.6)
  Equivalent XML performs more efficient comparisons of XML Literals when Nokogiri is included
* Soft dependency on [Rack][] (~> 2.2)
* Soft dependency on [Sinatra][] (~> 2.1)

## Installation

The recommended installation method is via [RubyGems](https://rubygems.org/).
To install the latest official release of the `SPARQL` gem, do:

    % [sudo] gem install sparql

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/ruby-rdf/sparql.git

## Mailing List

* <https://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Authors

* [Gregg Kellogg](https://github.com/gkellogg) - <https://greggkellogg.net/>
* [Arto Bendiken](https://github.com/artob) - <https://ar.to/>
* [Pius Uzamere](https://github.com/pius) - <https://pius.me/>

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
  explicit [public domain dedication][PDD] on record from you,
  which you will be asked to agree to on the first commit to a repo within the organization.
  Note that the agreement applies to all repos in the [Ruby RDF](https://github.com/ruby-rdf/) organization.

## License

This is free and unencumbered public domain software. For more information,
see <https://unlicense.org/> or the accompanying {file:UNLICENSE}.

A copy of the [SPARQL EBNF][] and derived parser files are included in the repository, which are not covered under the UNLICENSE. These files are covered via the [W3C Document License](https://www.w3.org/Consortium/Legal/2002/copyright-documents-20021231).

[Ruby]:             https://ruby-lang.org/
[RDF]:              https://www.w3.org/RDF/
[RDF::DO]:          https://rubygems.org/gems/rdf-do
[RDF::Mongo]:       https://rubygems.org/gems/rdf-mongo
[Rack::LinkedData]: https://rubygems.org/gems/rack-linkeddata
[YARD]:             https://yardoc.org/
[YARD-GS]:          https://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              https://unlicense.org/#unlicensing-contributions
[SPARQL]:           https://en.wikipedia.org/wiki/SPARQL
[SPARQL 1.0]:       https://www.w3.org/TR/sparql11-query/
[SSE]:              https://jena.apache.org/documentation/notes/sse.html
[SXP]:              https://dryruby.github.io/sxp
[grammar]:          https://www.w3.org/TR/sparql11-query/#grammar
[RDF 1.1]:          https://www.w3.org/TR/rdf11-concepts
[RDF.rb]:           https://ruby-rdf.github.io/rdf
[SPARQL 1.2]:          https://www.w3.org/TR/sparql12-query
[Linked Data]:      https://rubygems.org/gems/linkeddata
[SPARQL doc]:       https://ruby-rdf.github.io/sparql/frames
[SPARQL XML]:       https://www.w3.org/TR/rdf-sparql-XMLres/
[SPARQL JSON]:      https://www.w3.org/TR/rdf-sparql-json-res/
[SPARQL EBNF]:      https://www.w3.org/TR/sparql12-query/#sparqlGrammar

[SSD]:              https://www.w3.org/TR/sparql11-service-description/
[Rack]:             https://rack.github.io
[Sinatra]:          https://www.sinatrarb.com/
[conneg]:           https://en.wikipedia.org/wiki/Content_negotiation

[SPARQL 1.1 Query]:                             https://www.w3.org/TR/sparql11-query/
[SPARQL 1.1 Update]:                            https://www.w3.org/TR/sparql11-update/
[SPARQL 1.1 Service Description]:               https://www.w3.org/TR/sparql11-service-description/
[SPARQL 1.1 Federated Query]:                   https://www.w3.org/TR/sparql11-federated-query/
[SPARQL 1.1 Query Results JSON Format]:         https://www.w3.org/TR/sparql11-results-json/
[SPARQL 1.1 Query Results CSV and TSV Formats]: https://www.w3.org/TR/sparql11-results-csv-tsv/
[SPARQL Query Results XML Format]:              https://www.w3.org/TR/rdf-sparql-XMLres/
[SPARQL 1.1 Entailment Regimes]:                https://www.w3.org/TR/sparql11-entailment/
[SPARQL 1.1 Protocol]:                          https://www.w3.org/TR/sparql11-protocol/
[SPARQL 1.1 Graph Store HTTP Protocol]:         https://www.w3.org/TR/sparql11-http-rdf-update/
[Linked Data Platform]: https://www.w3.org/TR/ldp/
