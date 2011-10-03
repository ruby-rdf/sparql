# SPARQL for RDF.rb

This is a [Ruby][] implementation of the [SPARQL][] algebra for [RDF.rb][].

## Features

* 100% free and unencumbered [public domain](http://unlicense.org/) software.
* [SPARQL 1.0][] query parsing and execution
* SPARQL results as [XML][SPARQL XML] or [JSON][SPARQL JSON].
* SPARQL CONSTRUCT or DESCRIBE serialized based on Format, Extension of Mime Type
  using available RDF Writers (see [Linked Data](http://rubygems.org/gems/linkeddata))
* SPARQL Client for accessing remote SPARQL endpoints.
* Helper method for describing [SPARQL Service Description][]
* Compatible with Ruby Ruby 1.9.x.
* Compatible with older Ruby versions with the help of the [Backports][] gem.
* Supports Unicode query strings both on Ruby 1.8.x and 1.9.x.

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
    * {SPARQL::Grammar::Lexer}

## Dependencies

* [Ruby](http://ruby-lang.org/) (>= 1.9) or (>= 1.8.1 with [Backports][])
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.4)
* [SPARQL::Client](https://rubygems.org/gems/sparql-client) (>= 0.0.11)
* [SXP](https://rubygems.org/gems/sxp) (>= 0.0.15)
* [Builder](https://rubygems.org/gems/builder) (>= 3.0.0)
* [JSON](https://rubygems.org/gems/json) (>= 1.5.1)

## Installation

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `SPARQL` gem, do:

    % [sudo] gem install sparql

## Download

To get a local working copy of the development repository, do:

    % git clone git://github.com/gkellogg/sparql.git

## Mailing List

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

## Authors

* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>
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

[Ruby]:             http://ruby-lang.org/
[RDF]:              http://www.w3.org/RDF/
[YARD]:             http://yardoc.org/
[YARD-GS]:          http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              http://lists.w3.org/Archives/Public/public-rdf-ruby/2010May/0013.html
[SPARQL]:           http://en.wikipedia.org/wiki/SPARQL
[SPARQL 1.0]:       http://www.w3.org/TR/rdf-sparql-query/
[SPARQL 1.1]:       http://www.w3.org/TR/sparql11-query/
[SSE]:              http://openjena.org/wiki/SSE
[SXP]:              http://sxp.rubyforge.org/
[grammar]:          http://www.w3.org/TR/rdf-sparql-query/#grammar
[RDF.rb]:           http://rdf.rubyforge.org/
[YARD]:             http://yardoc.org/
[YARD-GS]:          http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:              http://unlicense.org/#unlicensing-contributions
[Backports]:        http://rubygems.org/gems/backports
[SPARQL doc]:       http://rubydoc.info/github/gkellogg/sparql/frames
[SPARQL XML]:       http://www.w3.org/TR/rdf-sparql-XMLres/
[SPARQL JSON]:      http://www.w3.org/TR/rdf-sparql-json-res/
[SPARQL Protocol]:  http://www.w3.org/TR/rdf-sparql-protocol/
[SPARQL Service]:   http://www.w3.org/TR/sparql11-service-description/
