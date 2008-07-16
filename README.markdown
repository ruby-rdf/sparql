sparql Release 0.0.1 (July 15th 2008) 
===================================

**Git**:  [http://github.com/pius/sparql](http://github.com/pius/sparql)   
**Author**:    Pius Uzamere, [The Uyiosa Corporation](http://www.uyiosa.com)

**Copyright**: 2008


SYNOPSIS
--------

sparql is a library for Ruby that formally implements the [SPARQL grammar](http://www.w3.org/TR/rdf-sparql-query/#grammar) as a parsing expression grammar (PEG).  The grammar is implemented in a fantastic syntax language called [Treetop](http://treetop.rubyforge.org).


FEATURE LIST
------------
                                                                              
1. **As of right now (20:28 EST, July 15, 2008) can parse basic SPARQL statements**: When finished, this library will be able to parse arbitrary SPARQL queries and can serve as a maintainable reference implementation in Ruby.

2.  **Starting point for providing SPARQL endpoints for arbitrary datastores**: When completed, this library will provide hooks that allow a Ruby developer to easily define a translation from SPARQL to another query language or API of their choosing.  Ideally, this will be done using a simple YAML configuration file.

3. **Fully Composable**: Because parsing expression grammars are closed under composition, you can compose this grammar with other Treetop grammars with relative ease.

USAGE
-----

First of all, it's worth noting that this library isn't ready to use.  If you insist on using it, then you'll need to do the following:

1. **Install the Gem**

Make sure you've upgraded to RubyGems 1.2.  Then, if you've never installed a gem from GitHub before then do this:

  > gem sources -a http://gems.github.com (you only have to do this once)

Then:

  > sudo gem install pius-sparql

2. **Make Sure You've Got the Dependencies installed**

sparql depends on Treetop (http://github.com/nathansobo/treetop).

  > sudo gem install treetop

3. **Require the gem in your code, play with it**

As of this minute, the code won't be that useful to you, as it can only parse a small subset of SPARQL and the translation hooks have not been added yet.  That being said, stay tuned.  I think development on this is going to move fairly quickly because Treetop is such a joy to write the PEG in.

Anyway, you can get started by doing the following in IRB.

  > irb(main):001:0> require 'rubygems'

  > => true

  > irb(main):002:0> gem 'pius-sparql'

  > => true

  > irb(main):003:0> require 'sparql'

  > => true

  > irb(main):004:0> parser = SparqlParser.new

  > => #SparqlParser:0x1270bcc @consume_all_input=true

  > irb(main):005:0> syntaxtree = parser.parse('SELECT ?foo ?bar WHERE { ?x foaf:knows ?y . ?z foaf:name ?y . }')


4. **Read the documentation**

Actually, scratch that.  I don't have very good documentation yet.  :(  But I do encourage you to take a look at lib/sparql/sparql.treetop and get a sense of the grammar.  In addition, check out the [formal specification of the SPARQL grammar](http://www.w3.org/TR/rdf-sparql-query/#grammar) so you can see how the Treetop grammar relates to it.

5. **Contribute!**

Fork my repository (http://github.com/pius/sparql), make some changes, and send along a pull request!

**I need help with IRIs.**  If you could take a look at the RDF grammar and write the code for parsing [70] (IRI_REF) in Treetop, that would be a great help.
                                                                              

COPYRIGHT
---------                                                                 

sparql was created in 2008 by Pius Uzamere (pius -AT- alum -DOT- mit -DOT- edu) and is    
licensed under the MIT license.
