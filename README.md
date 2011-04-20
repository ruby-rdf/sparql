SPARQL for RDF.rb
==================================

This gem combines several other gems to create a complete [Ruby][] [SPARQL 1.0][] solution
using [RDF.rb][].

Features
--------

* 100% free and unencumbered [public domain](http://unlicense.org/) software.
* [SPARQL 1.0][] query parsing and execution
* SPARQL results as [XML][SPARQL XML] or [JSON][SPARQL JSON].
* SPARQL CONSTRUCT or DESCRIBE serialized based on Format, Extension of Mime Type
  using available RDF Writers (see [Linked Data](http://rubygems.org/gems/linkeddata))
* SPARQL Client for accessing remote SPARQL endpoints.
* Helper method for describing [SPARQL Service Description][]
* Compatible with Ruby 1.8.7+, Ruby 1.9.x, and JRuby 1.4/1.5.
* Supports Unicode query strings both on Ruby 1.8.x and 1.9.x.

Examples
--------

    require 'rubygems'
    require 'sparql'

Documentation
-------------

<http://sparql.rubyforge.org>

* {SPARQL}

Dependencies
------------

* [Ruby](http://ruby-lang.org/) (>= 1.8.7) or (>= 1.8.1 with [Backports][])
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.4.0)
* [SPARQL::Algebra](https://rubygems.org/gems/sparql-algebra) (>= 0.0.7)
* [SPARQL::Client](https://rubygems.org/gems/sparql-client) (>= 0.0.10)
* [SPARQL::Grammar](https://rubygems.org/gems/sparql-grammar) (>= 0.0.5)
* [SXP](https://rubygems.org/gems/sxp) (>= 0.0.15)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the `SPARQL` gem, do:

    % [sudo] gem install sparql

Download
--------

To get a local working copy of the development repository, do:

    % git clone git://github.com/gkellogg/sparql.git

Mailing List
------------

* <http://lists.w3.org/Archives/Public/public-rdf-ruby/>

Author
------

* [Arto Bendiken](http://github.com/bendiken) - <http://ar.to/>
* [Ben Lavender](http://github.com/bhuga) - <http://bhuga.net/>
* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>
* [Pius Uzamere](http://github.com/pius) - <http://pius.me/>


Contributing
------------

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

License
-------

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying {file:UNLICENSE} file.

[Ruby]:       http://ruby-lang.org/
[RDF]:        http://www.w3.org/RDF/
[SPARQL]:     http://en.wikipedia.org/wiki/SPARQL
[SPARQL 1.0]: http://www.w3.org/TR/rdf-sparql-query/
[SPARQL 1.1]: http://www.w3.org/TR/sparql11-query/
[SSE]:        http://openjena.org/wiki/SSE
[SXP]:        http://sxp.rubyforge.org/
[grammar]:    http://www.w3.org/TR/rdf-sparql-query/#grammar
[RDF.rb]:     http://rdf.rubyforge.org/
[YARD]:       http://yardoc.org/
[YARD-GS]:    http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
[PDD]:        http://unlicense.org/#unlicensing-contributions
[Backports]:  http://rubygems.org/gems/backports
[SPARQL XML]: http://www.w3.org/TR/rdf-sparql-XMLres/
[SPARQL JSON]:http://www.w3.org/TR/rdf-sparql-json-res/
[SPARQL Service]: http://www.w3.org/TR/sparql11-service-description/