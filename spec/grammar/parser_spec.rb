require_relative '../spec_helper'
require_relative 'parser_shared_examples'

class SPARQL::Grammar::Parser
  # Class method version to aid in specs
  def self.variable(id, distinguished = true)
    SPARQL::Grammar::Parser.new.send(:variable, id, distinguished)
  end
end

describe SPARQL::Grammar::Parser do
  before(:each) {$stderr = StringIO.new}
  after(:each) {$stderr = STDERR}

  describe "#initialize" do
    it "accepts a string query" do |example|
      expect {
        described_class.new("foo") {
          raise "huh" unless input == "foo"
          }
        }.not_to raise_error
    end

    it "accepts a StringIO query" do |example|
      expect {
        described_class.new(StringIO.new("foo")) {
          raise "huh" unless input == "foo"
          }
        }.not_to raise_error
    end
  end

  describe "when matching the QueryUnit production rule", production: :QueryUnit, all_vars: true do
    {
      empty: ["", nil],
      select: [
        %q(SELECT * FROM <a> WHERE {?a ?b ?c}),
        %q((dataset (<a>) (project () (bgp (triple ?a ?b ?c)))))
      ],
      construct: [
        %q(CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}),
        %q((construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
      describe: [
        %q(DESCRIBE * FROM <a> WHERE {?a ?b ?c}),
        %q((describe () (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      ask: [
        "ASK WHERE {GRAPH <a> {?a ?b ?c}}",
        %q((ask (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the Query production rule", production: :Query, all_vars: true do
    {
      "base" => [
        "BASE <foo/> SELECT * WHERE { <a> <b> <c> }",
        %q((base <foo/> (project () (bgp (triple <a> <b> <c>)))))
      ],
      "prefix(1)" => [
        "PREFIX : <http://example.com/> SELECT * WHERE { :a :b :c }",
        %q((prefix ((: <http://example.com/>)) (project () (bgp (triple :a :b :c)))))
      ],
      "prefix(2)" => [
        "PREFIX : <foo#> PREFIX bar: <bar#> SELECT * WHERE { :a :b bar:c }",
          %q((prefix ((: <foo#>) (bar: <bar#>)) (project () (bgp (triple :a :b bar:c)))))
      ],
      "base+prefix" => [
        "BASE <http://baz/> PREFIX : <http://foo#> PREFIX bar: <http://bar#> SELECT * WHERE { <a> :b bar:c }",
        %q((base <http://baz/> (prefix ((: <http://foo#>) (bar: <http://bar#>)) (project () (bgp (triple <a> :b bar:c))))))
      ],
      "from" => [
        "SELECT * FROM <a> WHERE {?a ?b ?c}",
        %q((dataset (<a>) (project () (bgp (triple ?a ?b ?c)))))
      ],
      "from named" => [
        "SELECT * FROM NAMED <a> WHERE {?a ?b ?c}",
        %q((dataset ((named <a>)) (project () (bgp (triple ?a ?b ?c)))))
      ],
      "graph" => [
        "SELECT * WHERE {GRAPH <a> {?a ?b ?c}}",
        %q((project () (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
      "optional" => [
        "SELECT * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}",
        %q((project () (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "join" => [
        "SELECT * WHERE {?a ?b ?c {?d ?e ?f}}",
        %q((project () (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "union" => [
        "SELECT * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}",
        %q((project () (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "Var+" => [
        "SELECT ?a ?b WHERE {?a ?b ?c}",
        %q((project (?a ?b) (bgp (triple ?a ?b ?c))))
      ],
      "distinct(1)" => [
        "SELECT DISTINCT * WHERE {?a ?b ?c}",
        %q((distinct (project () (bgp (triple ?a ?b ?c)))))
      ],
      "distinct(2)" => [
        "SELECT DISTINCT ?a ?b WHERE {?a ?b ?c}",
        %q((distinct (project (?a ?b) (bgp (triple ?a ?b ?c)))))
      ],
      "reduced(1)" => [
        "SELECT REDUCED * WHERE {?a ?b ?c}",
        %q((reduced (project () (bgp (triple ?a ?b ?c)))))
      ],
      "reduced(2)" => [
        "SELECT REDUCED ?a ?b WHERE {?a ?b ?c}",
        %q((reduced (project (?a ?b) (bgp (triple ?a ?b ?c)))))
      ],
      "filter(1)" => [
        "SELECT * WHERE {?a ?b ?c FILTER (?a)}",
        %q((project () (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
      "filter(2)" => [
        "SELECT * WHERE {FILTER (?a) ?a ?b ?c}",
        %q((project () (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
      "filter(3)" => [
        "SELECT * WHERE { FILTER (?o>5) . ?s ?p ?o }",
        %q((project () (filter (> ?o 5) (bgp (triple ?s ?p ?o)))))
      ],
      "construct from" => [
        "CONSTRUCT {?a ?b ?c} FROM <a> WHERE {?a ?b ?c}",
        %q((construct ((triple ?a ?b ?c)) (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      "construct from named" => [
        "CONSTRUCT {?a ?b ?c} FROM NAMED <a> WHERE {?a ?b ?c}",
        %q((construct ((triple ?a ?b ?c)) (dataset ((named <a>)) (bgp (triple ?a ?b ?c)))))
      ],
      "construct graph" => [
        "CONSTRUCT {?a ?b ?c} WHERE {GRAPH <a> {?a ?b ?c}}",
        %q((construct ((triple ?a ?b ?c)) (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
      "construct optional" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}",
        %q((construct ((triple ?a ?b ?c)) (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct join" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c {?d ?e ?f}}",
        %q((construct ((triple ?a ?b ?c)) (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct union" => [
        "CONSTRUCT {?a ?b ?c} WHERE {{?a ?b ?c} UNION {?d ?e ?f}}",
        %q((construct ((triple ?a ?b ?c)) (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))))
      ],
      "construct filter" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}",
        %q((construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c)))))
      ],
      "describe" => [
        "DESCRIBE * FROM <a> WHERE {?a ?b ?c}", %q((describe () (dataset (<a>) (bgp (triple ?a ?b ?c)))))
      ],
      "ask" => [
        "ASK WHERE {GRAPH <a> {?a ?b ?c}}", %q((ask (graph <a> (bgp (triple ?a ?b ?c)))))
      ],
      "count" => [
        %q(SELECT (COUNT(?O) AS ?C) WHERE {?S ?P ?O}), %q((project (?C) (extend ((?C ??.0)) (group () ((??.0 (count ?O))) (bgp (triple ?S ?P ?O))))))
      ],
      "illegal bind variable" => [
        %q(SELECT * WHERE { ?s ?p ?o . BIND (?p AS ?o) }),
        EBNF::LL1::Parser::Error
      ],
      "illegal bind variable (graph name)" => [
        %q(SELECT * WHERE { GRAPH ?g {?s ?p ?o} . BIND (?p AS ?g) }),
        EBNF::LL1::Parser::Error
      ],

      # Value clauses
      "Multi-variable values" => [
        %q(PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
           SELECT ?id (ADJUST(?d, ?tz) AS ?adjusted)
           WHERE {
             VALUES (?id ?tz ?d) {
               (1 "-PT10H"^^xsd:dayTimeDuration "2002-03-07"^^xsd:date)
             }
           }),
        %q((prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>))
            (project (?id ?adjusted)
             (extend ((?adjusted (adjust ?d ?tz)))
              (table
               (vars ?id ?tz ?d)
               (row (?id 1) (?tz "-PT10H"^^xsd:dayTimeDuration) (?d "2002-03-07"^^xsd:date))) )) ))
      ],
      "InlineData" => [
        %q(SELECT ?book ?title ?price {
              VALUES ?book { :book1 }
              ?book :title ?title ; :price ?price .
           }),
        %q((project (?book ?title ?price)
            (join
             (table (vars ?book) (row (?book <book1>)))
             (bgp (triple ?book <title> ?title) (triple ?book <price> ?price))) ))
      ],
      "ValuesClause" => [
        %q(SELECT ?book ?title ?price { ?book :title ?title ; :price ?price . } VALUES ?book { :book1 }),
        %q((project (?book ?title ?price)
            (join
             (bgp (triple ?book <title> ?title) (triple ?book <price> ?price))
             (table (vars ?book) (row (?book <book1>))))))
      ],
      "ValuesClause no data" => [
        %q(SELECT * { } VALUES () { }),
        %q((project () (join (bgp) (table (vars)))))
      ],
      "InlineDataFull" => [
        %q(SELECT ?book {{?book :title ?title}} VALUES (?book) {(:book1)}),
        %q((project (?book) (join (bgp (triple ?book <title> ?title)) (table (vars ?book) (row (?book <book1>))))))
      ],

      # Annotations
      "Empty Annotation with IRI reifier" => [
        %q(SELECT * WHERE {:s :p :o ~ :r}),
        %[(project ()
           (bgp (triple <s> <p> <o>)
            (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))))]
      ],
      "Multiple Empty Annotations with IRI reifiers" => [
        %q(SELECT * WHERE {:s :p :o ~ :r1 ~ :r2}),
        %[(project ()
           (bgp (triple <s> <p> <o>)
            (triple <r1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple <r2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))))]
      ],
      "Annotation with IRI reifier" => [
        %q(SELECT * WHERE {:s :p :o ~ :r {| :p1 :o1 |}}),
        %[(project ()
           (bgp (triple <s> <p> <o>)
            (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple <r> <p1> <o1>)))]
      ],
      "Annotation with Blank Node reifier" => [
        %q(SELECT * WHERE {:s :p :o ~ _:r {| :p1 :o1 |}}),
        %[(project ()
           (bgp (triple <s> <p> <o>)
            (triple ??r <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple ??r <p1> <o1>)))]
      ],
      "Annotation with empty reifier" => [
        %q(SELECT * WHERE {:s :p :o ~ {| :p1 :o1 |}}),
        %[(project ()
           (bgp (triple <s> <p> <o>)
            (triple ??0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple ??0 <p1> <o1>)))]
      ],
      "Annotation with no reifier" => [
        %q(SELECT * WHERE {:s :p :o {| :p1 :o1 |}}),
        %[(project ()
           (bgp (triple <s> <p> <o>)
            (triple ??0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple ??0 <p1> <o1>)))]
      ],
      "Multiple Annotations with IRI reifiers" => [
        %q(SELECT * WHERE {:s :p :o ~ :id1 {| :r :z |} ~ :id2 {| :s :w |} }),
        %[(project ()
           (bgp (triple <s> <p> <o>)
            (triple <id1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple <id1> <r> <z>)
            (triple <id2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple <id2> <s> <w>)))]
      ],
      "Multiple Annotations with empty reifiers" => [
        %q(SELECT * WHERE {:s :p :o ~ {| :r :z |} ~ {| :s :w |} }),
        %[(project ()
           (bgp (triple <s> <p> <o>)
            (triple ??0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple ??0 <r> <z>)
            (triple ??1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple ??1 <s> <w>)))]
      ],
      "Annotation with reified triple" => [
        %q(SELECT * {?bob :age ?age ~ :r {| :p << :s1 :p1 :o1 ~ :r1>> |}}),
        %q[(project ()
            (bgp
             (triple ?bob <age> ?age)
             (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
              (qtriple ?bob <age> ?age))
             (triple <r> <p> <r1>)
             (triple <r1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
              (qtriple <s1> <p1> <o1>))))]
      ],
      "Reified Triple without reifier as subject" => [
        %q(SELECT * WHERE {<<:s :p :o>> :p1 :o1}),
        %[(project ()
           (bgp
            (triple ??1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple ??1 <p1> <o1>)))]
      ],
      "Reified Triple with empty reifier as subject" => [
        %q(SELECT * WHERE {<<:s :p :o ~>> :p1 :o1}),
        %[(project ()
           (bgp
            (triple ??1 <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple ??1 <p1> <o1>)))]
      ],
      "Reified Triple with blank node reifier as subject" => [
        %q(SELECT * WHERE {<<:s :p :o ~ _:r>> :p1 :o1}),
        %[(project () 
           (bgp
            (triple ??r <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple ??r <p1> <o1>)))]
      ],
      "Reified Triple with IRI reifier as subject" => [
        %q(SELECT * WHERE {<<:s :p :o ~ :r>> :p1 :o1}),
        %[(project () 
           (bgp
            (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies> (qtriple <s> <p> <o>))
            (triple <r> <p1> <o1>)))]
      ],
      "Construct Annotation with IRI reifier and annotation block" => [
        %q(CONSTRUCT { :s :p :o ~:r {| :y :z |}} WHERE {:s :p :o}),
        %[(construct
           (
            (triple <s> <p> <o>)
            (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>))
            (triple <r> <y> <z>))
           (bgp
            (triple <s> <p> <o>)))]
      ],
      "Construct Annotation with no reifier and annotation block" => [
        %q(CONSTRUCT { :s :p :o {| :y :z |}} WHERE {:s :p :o}),
        %[(construct
           (
            (triple <s> <p> <o>)
            (triple _:b0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>))
            (triple _:b0 <y> <z>))
           (bgp
            (triple <s> <p> <o>)))]
      ],
      "Construct Empty Annotation with IRI reifier" => [
        %q(CONSTRUCT { :s :p :o ~:r} WHERE {:s :p :o ~ :r}),
        %[(construct
           (
            (triple <s> <p> <o>)
            (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>)))
           (bgp
            (triple <s> <p> <o>)
            (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>)) ))]
      ],
      "Construct Empty Annotation with empty reifier" => [
        %q(CONSTRUCT { :s :p :o ~} WHERE {:s :p :o ~ :r}),
        %[(construct
           (
            (triple <s> <p> <o>)
            (triple _:b0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>)))
           (bgp
            (triple <s> <p> <o>)
            (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>)) ))]
      ],
      "Construct Empty Annotation with blank node reifier and annotation block" => [
        %q(CONSTRUCT { :s :p :o ~_:r} WHERE {:s :p :o ~ :r}),
        %[(construct
           (
            (triple <s> <p> <o>)
            (triple _:r <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>)))
           (bgp
            (triple <s> <p> <o>)
            (triple <r> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>)) ))]
      ],
      "Construct Multiple Empty Annotations with IRI reifiers" => [
        %q(CONSTRUCT { :s :p :o ~:r1 ~:r2} WHERE {:s :p :o ~ :r1 ~ :r2}),
        %[(construct
           ((triple <s> <p> <o>)
            (triple <r1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>))
            (triple <r2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>)))
           (bgp
            (triple <s> <p> <o>)
            (triple <r1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>))
            (triple <r2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>)) ))
          ]
      ],
      "Construct Multiple Annotations with IRI reifiers" => [
        %q(CONSTRUCT {:s :p :o ~ :id1 {| :r :z |} ~ :id2 {| :s :w |} } WHERE {:s :p :o }),
        %[(construct
           ((triple <s> <p> <o>)
            (triple <id1> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>))
            (triple <id1> <r> <z>)
            (triple <id2> <http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies>
             (qtriple <s> <p> <o>))
            (triple <id2> <s> <w>))
           (bgp (triple <s> <p> <o>)))]
      ],
      "constructwhere01" => [
        %q(CONSTRUCT WHERE { ?S ?P ?O }),
        %q[(construct ((triple ?S ?P ?O)) (bgp (triple ?S ?P ?O)))]
      ],
      "constructwhere03" => [
        %q(CONSTRUCT WHERE { :s2 :p ?o1, ?o2 }),
        %q[(construct ((triple <s2> <p> ?o1) (triple <s2> <p> ?o2)) (bgp (triple <s2> <p> ?o1) (triple <s2> <p> ?o2)))]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, logger: RDF::Spec.logger, **example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "BGP Patterns", "SELECT * WHERE {%s}"
  end

  describe "when matching the Prologue production rule", production: :Prologue do
    it "sets base_uri to <http://example.org> given 'BASE <http://example.org/>'" do |example|
      p = parser(nil, resolve_iris: true).call(%q(BASE <http://example.org/>))
      p.parse(example.metadata[:production])
      expect(p.send(:base_uri)).to eq RDF::URI('http://example.org/')
    end

    it "sets prefix : to 'foobar' given 'PREFIX : <foobar>'" do |example|
      p = parser(nil, resolve_iris: true).call(%q(PREFIX : <foobar>))
      p.parse(example.metadata[:production])
      expect(p.send(:prefix, nil)).to eq 'foobar'
      expect(p.send(:prefixes)[nil]).to eq 'foobar'
    end

    it "sets prefix foo: to 'bar' given 'PREFIX foo: <bar>'" do |example|
      p = parser(nil, resolve_iris: true).call(%q(PREFIX foo: <bar>))
      p.parse(example.metadata[:production])
      expect(p.send(:prefix, :foo)).to eq 'bar'
      expect(p.send(:prefix, "foo")).to eq 'bar'
      expect(p.send(:prefixes)[:foo]).to eq 'bar'
    end

    {
      "base" => [
        %q(BASE <http://example.org/>), [:BaseDecl, RDF::URI("http://example.org/")]
      ],
      "empty prefix" => [
        %q(PREFIX : <foobar>),
        [:PrefixDecl, SPARQL::Algebra::Operator::Prefix.new([[:":", RDF::URI("foobar")]], [])]
      ],
      "prefix" => [
        %q(PREFIX foo: <bar>),
        [:PrefixDecl, SPARQL::Algebra::Operator::Prefix.new([[:"foo:", RDF::URI("bar")]], [])]
      ],
      "both prefixes" => [
        %q(PREFIX : <foobar> PREFIX foo: <bar>),
        [:PrefixDecl,
          SPARQL::Algebra::Operator::Prefix.new([[:":", RDF::URI("foobar")]], []),
          SPARQL::Algebra::Operator::Prefix.new([[:"foo:", RDF::URI("bar")]], [])
        ]
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the SelectQuery production rule", production: :SelectQuery, all_vars: true do
    {
      "from" => [
        "SELECT * FROM <a> WHERE {?a ?b ?c}",
        %q[(dataset (<a>) (project () (bgp (triple ?a ?b ?c))))]
      ],
      "from (lc)" => [
        "select * from <a> where {?a ?b ?c}",
        %q[(dataset (<a>) (project () (bgp (triple ?a ?b ?c))))]
      ],
      "from named" => [
        "SELECT * FROM NAMED <a> WHERE {?a ?b ?c}",
        %q[(dataset ((named <a>)) (project () (bgp (triple ?a ?b ?c))))]
      ],
      "graph" => [
        "SELECT * WHERE {GRAPH <a> {?a ?b ?c}}",
        %q[(project () (graph <a> (bgp (triple ?a ?b ?c))))]
      ],
      "graph (var)" => [
        "SELECT * {GRAPH ?g { :x :b ?a . GRAPH ?g2 { :x :p ?x } }}",
        %q[(project ()
             (graph ?g
               (join
                 (bgp (triple <x> <b> ?a))
                 (graph ?g2
                   (bgp (triple <x> <p> ?x))))))]
      ],
      "optional" => [
        "SELECT * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}",
        %q[(project () (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "join" => [
        "SELECT * WHERE {?a ?b ?c {?d ?e ?f}}",
        %q[(project () (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "union" => [
        "SELECT * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}",
        %q[(project () (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "Var+" => [
        "SELECT ?a ?b WHERE {?a ?b ?c}",
        %q[(project (?a ?b) (bgp (triple ?a ?b ?c)))]
      ],
      "Expression" => [
        "SELECT (?c+10 AS ?z) WHERE {?a ?b ?c}",
        %q[(project (?z) (extend ((?z (+ ?c 10))) (bgp (triple ?a ?b ?c))))]
      ],
      "distinct(1)" => [
        "SELECT DISTINCT * WHERE {?a ?b ?c}",
        %q[(distinct (project () (bgp (triple ?a ?b ?c))))]
      ],
      "distinct(2)" => [
        "SELECT DISTINCT ?a ?b WHERE {?a ?b ?c}",
        %q[(distinct (project (?a ?b) (bgp (triple ?a ?b ?c))))]
      ],
      "reduced(1)" => [
        "SELECT REDUCED * WHERE {?a ?b ?c}",
        %q[(reduced (project () (bgp (triple ?a ?b ?c))))]
      ],
      "reduced(2)" => [
        "SELECT REDUCED ?a ?b WHERE {?a ?b ?c}",
        %q[(reduced (project (?a ?b) (bgp (triple ?a ?b ?c))))]
      ],
      "filter(1)" => [
        "SELECT * WHERE {?a ?b ?c FILTER (?a)}",
        %q[(project () (filter ?a (bgp (triple ?a ?b ?c))))]
      ],
      "filter(2)" => [
        "SELECT * WHERE {FILTER (?a) ?a ?b ?c}",
        %q[(project () (filter ?a (bgp (triple ?a ?b ?c))))]
      ],
      "filter(3)" => [
        "SELECT * WHERE { FILTER (?o>5) . ?s ?p ?o }",
        %q[(project () (filter (> ?o 5) (bgp (triple ?s ?p ?o))))]
      ],
      "bind(1)" => [
        "SELECT ?z {?s ?p ?o . BIND(?o+10 AS ?z)}",
        %q[(project (?z)
            (extend ((?z (+ ?o 10)))
             (bgp (triple ?s ?p ?o))))]
      ],
      "bind(2)" => [
        "SELECT ?o ?z ?z2 {?s ?p ?o . BIND(?o+10 AS ?z) BIND(?o+100 AS ?z2)}",
        %q[(project (?o ?z ?z2)
            (extend ((?z (+ ?o 10)) (?z2 (+ ?o 100)))
             (bgp (triple ?s ?p ?o))))]
      ],
      "group(1)" => [
        "SELECT ?s {?s :p ?v .} GROUP BY ?s",
        %q[(project (?s)
            (group (?s)
             (bgp (triple ?s <p> ?v))))]
      ],
      "group(2)" => [
        "SELECT ?s {?s :p ?v .} GROUP BY ?s ?w",
        %q[(project (?s)
            (group (?s ?w)
             (bgp (triple ?s <p> ?v))))]
      ],
      "group+expression" => [
        "SELECT ?w (SAMPLE(?v) AS ?S) {?s :p ?v . OPTIONAL { ?s :q ?w }} GROUP BY ?w",
        %q(
        (project (?w ?S)
          (extend ((?S ??.0))
            (group (?w) ((??.0 (sample ?v)))
              (leftjoin
                (bgp (triple ?s <p> ?v))
                (bgp (triple ?s <q> ?w))))))
        )
      ],

      # Vars
      "SELECT var" => [
        "SELECT ?a {?a :p :o}", %q[(project (?a) (bgp (triple ?a <p> <o>)))]
      ],
      "SELECT var+var" => [
        "SELECT ?a ?b {?a :p ?b}", %q[(project (?a ?b) (bgp (triple ?a <p> ?b)))]
      ],
      "SELECT *" => [
        "SELECT * {?a :p ?b}", %q[(project () (bgp (triple ?a <p> ?b)))]
      ],
      "GROUP BY COALESCE" => [
        %q(SELECT ?X (SAMPLE(?v) AS ?S) {
             ?s :p ?v .
             OPTIONAL { ?s :q ?w }
           }
           GROUP BY (COALESCE(?w, "1605-11-05"^^xsd:date) AS ?X)
        ),
        %q[(project (?X ?S)
            (extend ((?S ??.0))
             (group
              ((?X (coalesce ?w "1605-11-05"^^<date>)))
              ((??.0 (sample ?v)))
              (leftjoin
               (bgp (triple ?s <p> ?v))
               (bgp (triple ?s <q> ?w))))))]
      ],
      "GROUP HAVING" => [
        %q(SELECT ?s (AVG(?o) AS ?avg) WHERE { ?s ?p ?o } GROUP BY ?s HAVING (AVG(?o) <= 2.0)),
        %q[(project (?s ?avg)
            (filter (<= ??.1 2.0)
             (extend ((?avg ??.0))
              (group (?s) ((??.0 (avg ?o)) (??.1 (avg ?o)))
               (bgp (triple ?s ?p ?o))))))]
      ],
      "implicit group" => [
        %q(SELECT (COUNT(?O) AS ?C) WHERE { ?S ?P ?O }),
        %q[(project (?C)
            (extend ((?C ??.0))
              (group () ((??.0 (count ?O)))
                (bgp (triple ?S ?P ?O)))))]
      ],

      # SubSelect
      "Simple SubSelect" => [
        %q(SELECT (1 AS ?X ) { SELECT (2 AS ?Y ) {}}),
        %q[(project (?X) (extend ((?X 1)) (project (?Y) (extend ((?Y 2)) (bgp)))))]
      ],

      # Property Paths
      "sequence BGP and path" => [
        %q(SELECT * {?uri a ?type; :p1 / :p2 ?anotherURI}),
        %q[(project () (sequence (bgp (triple ?uri a ?type)) (path ?uri (seq <p1> <p2>) ?anotherURI)))]
      ],

      # Collections
      "Single element list" => [
        %q(SELECT ?p { :x ?p (1) . }),
        %q[(project (?p)
            (bgp
             (triple <x> ?p ??0)
             (triple ??0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#first> 1)
             (triple ??0 <http://www.w3.org/1999/02/22-rdf-syntax-ns#rest>
              <http://www.w3.org/1999/02/22-rdf-syntax-ns#nil>)))]
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end

    include_examples "BGP Patterns", "SELECT * WHERE {%s}"
  end

  describe "when matching the ConstructQuery production rule", production: :ConstructQuery do
    {
      "construct from" => [
        "CONSTRUCT {?a ?b ?c} FROM <a> WHERE {?a ?b ?c}",
        %q[(construct ((triple ?a ?b ?c)) (dataset (<a>) (bgp (triple ?a ?b ?c))))]
      ],
      "construct from named" => [
        "CONSTRUCT {?a ?b ?c} FROM NAMED <a> WHERE {?a ?b ?c}",
        %q[(construct ((triple ?a ?b ?c)) (dataset ((named <a>)) (bgp (triple ?a ?b ?c))))]
      ],
      "construct graph" => [
        "CONSTRUCT {?a ?b ?c} WHERE {GRAPH <a> {?a ?b ?c}}",
        %q[(construct ((triple ?a ?b ?c)) (graph <a> (bgp (triple ?a ?b ?c))))]
      ],
      "construct optional" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}",
        %q[(construct ((triple ?a ?b ?c)) (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "construct join" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c {?d ?e ?f}}",
        %q[(construct ((triple ?a ?b ?c)) (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "construct union" => [
        "CONSTRUCT {?a ?b ?c} WHERE {{?a ?b ?c} UNION {?d ?e ?f}}",
        %q[(construct ((triple ?a ?b ?c)) (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "construct filter" => [
        "CONSTRUCT {?a ?b ?c} WHERE {?a ?b ?c FILTER (?a)}",
        %q[(construct ((triple ?a ?b ?c)) (filter ?a (bgp (triple ?a ?b ?c))))]
      ],
      "construct empty" => [
        %q(CONSTRUCT {} WHERE {}),
        %q[(construct () (bgp))]
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the DescribeQuery production rule", production: :DescribeQuery do
    {
      "describe" => [
        "DESCRIBE * WHERE {?a ?b ?c}", %q[(describe () (bgp (triple ?a ?b ?c)))]
      ],
      "describe from" => [
        "DESCRIBE * FROM <a> WHERE {?a ?b ?c}", %q[(describe () (dataset (<a>) (bgp (triple ?a ?b ?c))))]
      ],
      "describe from named" => [
        "DESCRIBE * FROM NAMED <a> WHERE {?a ?b ?c}", %q[(describe () (dataset ((named <a>)) (bgp (triple ?a ?b ?c))))]
      ],
      "describe graph" => [
        "DESCRIBE * WHERE {GRAPH <a> {?a ?b ?c}}", %q[(describe () (graph <a> (bgp (triple ?a ?b ?c))))]
      ],
      "describe optional" => [
        "DESCRIBE * WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q[(describe () (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "describe join" => [
        "DESCRIBE * WHERE {?a ?b ?c {?d ?e ?f}}", %q[(describe () (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "describe union" => [
        "DESCRIBE * WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q[(describe () (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "describe filter" => [
        "DESCRIBE * WHERE {?a ?b ?c FILTER (?a)}", %q[(describe () (filter ?a (bgp (triple ?a ?b ?c))))]
      ],
      "no query" => [
        "DESCRIBE *", %q[(describe () (bgp))]
      ],
      "no query var" => [
        "DESCRIBE ?a", %q[(describe (?a) (bgp))]
      ],
      "no query from" => [
        "DESCRIBE * FROM <a>", %q[(describe () (dataset (<a>) (bgp)))]
      ],
      "iri" => [
        "DESCRIBE <a> WHERE {?a ?b ?c}", %q[(describe (<a>) (bgp (triple ?a ?b ?c)))]
      ],
      "var+iri" => [
        "DESCRIBE ?a <a> WHERE {?a ?b ?c}", %q[(describe (?a <a>) (bgp (triple ?a ?b ?c)))]
      ],
      "var+var" => [
        "DESCRIBE ?a ?b WHERE {?a ?b ?c}", %q[(describe (?a ?b) (bgp (triple ?a ?b ?c)))]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the AskQuery production rule", production: :AskQuery do
    {
      "ask" => [
        "ASK WHERE {?a ?b ?c}", %q[(ask (bgp (triple ?a ?b ?c)))]
      ],
      "ask from" => [
        "ASK FROM <a> WHERE {?a ?b ?c}", %q[(ask (dataset (<a>) (bgp (triple ?a ?b ?c))))]
      ],
      "ask from named" => [
        "ASK FROM NAMED <a> WHERE {?a ?b ?c}", %q[(ask (dataset ((named <a>)) (bgp (triple ?a ?b ?c))))]
      ],
      "ask graph" => [
        "ASK WHERE {GRAPH <a> {?a ?b ?c}}", %q[(ask (graph <a> (bgp (triple ?a ?b ?c))))]
      ],
      "ask optional" => [
        "ASK WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q[(ask (leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "ask join" => [
        "ASK WHERE {?a ?b ?c {?d ?e ?f}}", %q[(ask (join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "ask union" => [
        "ASK WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q[(ask (union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f))))]
      ],
      "ask filter" => [
        "ASK WHERE {?a ?b ?c FILTER (?a)}", %q[(ask (filter ?a (bgp (triple ?a ?b ?c))))]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the WhereClause production rule", production: :WhereClause do
    {
      "where" => [
        "WHERE {?a ?b ?c}", %q[(bgp (triple ?a ?b ?c))]
      ],
      "where graph" => [
        "WHERE {GRAPH <a> {?a ?b ?c}}", %q[(graph <a> (bgp (triple ?a ?b ?c)))]
      ],
      "where optional" => [
        "WHERE {?a ?b ?c OPTIONAL {?d ?e ?f}}", %q[(leftjoin (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))]
      ],
      "where join" => [
        "WHERE {?a ?b ?c {?d ?e ?f}}", %q[(join (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))]
      ],
      "where union" => [
        "WHERE {{?a ?b ?c} UNION {?d ?e ?f}}", %q[(union (bgp (triple ?a ?b ?c)) (bgp (triple ?d ?e ?f)))]
      ],
      "where filter" => [
        "WHERE {?a ?b ?c FILTER (?a)}", %q[(filter ?a (bgp (triple ?a ?b ?c)))]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end

    include_examples "BGP Patterns", "WHERE {%s}"
  end

  describe "when matching the SolutionModifier production rule", production: :SelectQuery do
    {
      "limit" => [
        "SELECT * {?a ?b ?c} LIMIT 1",
        %q[(slice _ 1 (bgp (triple ?a ?b ?c)))]
      ],
      "offset" => [
        "SELECT * {?a ?b ?c} OFFSET 2",
        %q[(slice 2 _ (bgp (triple ?a ?b ?c)))]
      ],
      "limit+offset" => [
        "SELECT * {?a ?b ?c} LIMIT 1 OFFSET 2",
        %q[(slice 2 1 (bgp (triple ?a ?b ?c)))]
      ],
      "offset+limit" => [
        "SELECT * {?a ?b ?c} OFFSET 2 LIMIT 1",
        %q[(slice 2 1 (bgp (triple ?a ?b ?c)))]
      ],
      "order asc" => [
        "SELECT * {?a ?b ?c} ORDER BY ASC (1)",
        %q[(order ((asc 1)) (bgp (triple ?a ?b ?c)))]
      ],
      "order desc" => [
        "SELECT * {?a ?b ?c} ORDER BY DESC (1)",
        %q[(order ((desc 1)) (bgp (triple ?a ?b ?c)))]
      ],
      "order var" => [
        "SELECT * {?a ?b ?c} ORDER BY ?a ?b ?c",
        %q[(order (?a ?b ?c) (bgp (triple ?a ?b ?c)))]
      ],
      "order var+asc+isURI" => [
        "SELECT * {?a ?b ?c} ORDER BY ?a ASC (1) isURI(<b>)",
        %q[(order (?a (asc 1) (isIRI <b>)) (bgp (triple ?a ?b ?c)))]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the GroupCondition production rule", production: :GroupCondition do
    {
      "BuiltInCall" => [
        %q(STR ("foo")), %q[(str "foo")]
      ],
      "FunctionCall" => [
        "<foo>('bar')", %q[(<foo> "bar")]
      ],
      "Expression" => [
        %q[(COALESCE(?w, "1605-11-05"^^<date>))],
        %q[(coalesce ?w "1605-11-05"^^<date>)]
      ],
      "Expression+VAR" => [
        %q[(COALESCE(?w, "1605-11-05"^^<date>))],
        %q[(coalesce ?w "1605-11-05"^^<date>)]
      ],
      "Var" => [
        "?s", %q(?s)
      ]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the OrderClause production rule", production: :OrderClause do
    {
      "order asc" => [
        "ORDER BY ASC (1)", [SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1))]
      ],
      "order desc" => [
        "ORDER BY DESC (?a)", [SPARQL::Algebra::Operator::Desc.new(RDF::Query::Variable.new("a"))]
      ],
      "order var" => [
        "ORDER BY ?a ?b ?c", [RDF::Query::Variable.new("a"), RDF::Query::Variable.new("b"), RDF::Query::Variable.new("c")]
      ],
      "order var+asc+isURI" => [
        "ORDER BY ?a ASC (1) isURI(<b>)", [RDF::Query::Variable.new("a"), SPARQL::Algebra::Operator::Asc.new(RDF::Literal(1)), SPARQL::Algebra::Operator::IsURI.new(RDF::URI("b"))]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the OrderCondition production rule", production: :OrderCondition do
    {
      "asc" => [
        "ASC (1)", SPARQL::Algebra::Expression[:asc, RDF::Literal(1)]
      ],
      "desc" => [
        "DESC (?a)", SPARQL::Algebra::Expression[:desc, RDF::Query::Variable.new("a")]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
    include_examples "FunctionCall"
    include_examples "BrackettedExpression"
    include_examples "BuiltInCall"
    include_examples "Var"
  end

  describe "when matching the Update production rule", production: :Update do
    {
      "insert" => [
        "INSERT DATA {<a> <b> <c>}",
        %q[(update (insertData ((triple <a> <b> <c>))))]
      ],
      "insert (LC)" => [
        "insert data {<a> <b> <c>}",
        %q[(update (insertData ((triple <a> <b> <c>))))]
      ],
      "clear" => [
        "CLEAR DEFAULT",
        %q[(update (clear default))]
      ],
      "clear (LC)" => [
        "clear default",
        %q[(update (clear default))]
      ],
      "load IRI" => [
        "LOAD <etc/doap.ttl>",
        %q[(update (load <etc/doap.ttl>))]
      ],
      "insert using" => [
        'INSERT { ?s ?p "q" } USING :g1 USING :g2 WHERE { ?s ?p ?o }',
        %q[(update
            (modify
            (using (<g1> <g2>) (bgp (triple ?s ?p ?o)))
            (insert ((triple ?s ?p "q")))))]
      ],
      "delete vars where" => [
        %q(DELETE { ?s ?p ?o } WHERE { :a :knows ?s . ?s ?p ?o }),
        %q[(update
            (modify
             (bgp (triple <a> <knows> ?s) (triple ?s ?p ?o))
             (delete ((triple ?s ?p ?o)))))]
      ],
      "delete where" => [
        %q(DELETE WHERE { :a :knows ?b }),
        %q[(update (deleteWhere ((triple <a> <knows> ?b))))]
      ],
      "delete insert" => [
        %q(DELETE { ?a :knows ?b . }
           WHERE { ?a :knows ?b . } ;
           INSERT { ?b :knows ?a . }
           WHERE { ?a :knows ?b .}),
        %q[(update
            (modify
             (bgp (triple ?a <knows> ?b))
             (delete ((triple ?a <knows> ?b))))
            (modify
             (bgp (triple ?a <knows> ?b))
             (insert ((triple ?b <knows> ?a)))))]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the Load production rule", production: :Load do
    {
      "load iri" => [%q(LOAD <a>), %[(load <a>)]],
      "load iri silent" => [%q(LOAD SILENT <a>), %q[(load silent <a>)]],
      "load into" => [%q(LOAD <a> INTO GRAPH <b>), %q[(load <a> <b>)]],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the Clear production rule", production: :Clear do
    {
      "clear all" => [%q(CLEAR ALL), %[(clear all)]],
      "clear all (LC)" => [%q(clear all), %[(clear all)]],
      "clear all (Mixed)" => [%q(cLeAr AlL), %[(clear all)]],
      "clear all silent" => [%q(CLEAR SILENT ALL), %[(clear silent all)]],
      "clear default" => [%q(CLEAR DEFAULT), %((clear default))],
      "clear graph" => [%q(CLEAR GRAPH <g1>), %[(clear <g1>)]],
      "clear named" => [%q(CLEAR NAMED), %[(clear named)]],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the Drop production rule", production: :Drop do
    {
      "drop all" => [%q(DROP ALL), %[(drop all)]],
      "drop all silent" => [%q(DROP SILENT ALL), %[(drop silent all)]],
      "drop default" => [%q(DROP DEFAULT), %[(drop default)]],
      "drop graph" => [%q(DROP GRAPH <g1>), %[(drop <g1>)]],
      "drop named" => [%q(DROP NAMED), %[(drop named)]],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the Create production rule", production: :Create do
    {
      "create graph" => [%q(CREATE GRAPH <g1>), %[(create <g1>)]],
      "create graph silent" => [%q(CREATE SILENT GRAPH <g1>), %[(create silent <g1>)]],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the Add production rule", production: :Add do
    {
      "add default default" => [%q(ADD DEFAULT TO DEFAULT), %q((add default default))],
      "add iri default" => [%q(ADD <a> TO DEFAULT), %q((add <a> default))],
      "add default iri" => [%q(ADD DEFAULT TO <a>), %q((add default <a>))],
      "add graph iri default" => [%q(ADD GRAPH <a> TO DEFAULT), %q((add <a> default))],
      "add default graph iri" => [%q(ADD DEFAULT TO GRAPH <a>), %q((add default <a>))],
      "add silent iri iri" => [%q(ADD SILENT <a> TO <b>), %q((add silent <a> <b>))]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the Move production rule", production: :Move do
    {
      "move default default" => [%q(MOVE DEFAULT TO DEFAULT), %q((move default default))],
      "move iri default" => [%q(MOVE <a> TO DEFAULT), %q((move <a> default))],
      "move default iri" => [%q(MOVE DEFAULT TO <a>), %q((move default <a>))],
      "move graph iri default" => [%q(MOVE GRAPH <a> TO DEFAULT), %q((move <a> default))],
      "move default graph iri" => [%q(MOVE DEFAULT TO GRAPH <a>), %q((move default <a>))],
      "move silent iri iri" => [%q(MOVE SILENT <a> TO <b>), %q((move silent <a> <b>))]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the Copy production rule", production: :Copy do
    {
      "copy default default" => [%q(COPY DEFAULT TO DEFAULT), %q((copy default default))],
      "copy iri default" => [%q(COPY <a> TO DEFAULT), %q((copy <a> default))],
      "copy default iri" => [%q(COPY DEFAULT TO <a>), %q((copy default <a>))],
      "copy graph iri default" => [%q(COPY GRAPH <a> TO DEFAULT), %q((copy <a> default))],
      "copy default graph iri" => [%q(COPY DEFAULT TO GRAPH <a>), %q((copy default <a>))],
      "copy silent iri iri" => [%q(COPY SILENT <a> TO <b>), %q((copy silent <a> <b>))]
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the UsingClause production rule", production: :UsingClause do
    {
      "using iri" => [
        %q(USING <a>), RDF::URI("a")
      ],
      "using pname" => [
        %q(USING :a), RDF::URI("a")
      ],
      "using named" => [
        %q(USING NAMED <a>), [:named, RDF::URI("a")]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the InsertData production rule", production: :InsertData do
    {
      "empty triple" => [
        %q(INSERT DATA {}),
        %q((insertData ()))
      ],
      "insert triple" => [
        %q(INSERT DATA {<a> <knows> <b> .}),
        %q((insertData ((triple <a> <knows> <b>))))
      ],
      "insert graph" => [
        %q(INSERT DATA {GRAPH <http://example.org/g1> {<a> <knows> <b> .}}),
        %q((insertData ((graph <http://example.org/g1> ((triple <a> <knows> <b>))))))
      ],
      #"insert triple newline" => [
      #  %(INSERT\nDATA {<a> <knows> <b> .}),
      #  %q((insertData ((triple <a> <knows> <b>))))
      #],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the DeleteData production rule", production: :DeleteData do
    {
      "empty triple" => [
        %q(DELETE DATA {}),
        %q((deleteData ()))
      ],
      "delete triple" => [
        %q(DELETE DATA {<a> <knows> <b> .}),
        %q((deleteData ((triple <a> <knows> <b>))))
      ],
      "delete graph" => [
        %q(DELETE DATA {GRAPH <http://example.org/g1> {<a> <knows> <b> .}}),
        %q((deleteData ((graph <http://example.org/g1> ((triple <a> <knows> <b>))))))
      ],
      "delete triple and graph" => [
        %q(DELETE DATA {
          <a> <knows> <b> .
          GRAPH <http://example.org/g1> {<a> <knows> <b> .}
          <c> <knows> <d> .
        }),
        %q((deleteData ((triple <a> <knows> <b>)
                        (graph <http://example.org/g1> ((triple <a> <knows> <b>)))
                        (triple <c> <knows> <d>))))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the GroupGraphPattern production rule", production: :GroupGraphPattern do
    {
      # From data/Optional/q-opt-1.rq
      "q-opt-1.rq" => [
        "{<a><b><c> OPTIONAL {<d><e><f>}}",
        %q((leftjoin 
          (bgp (triple <a> <b> <c>))
          (bgp (triple <d> <e> <f>))))
      ],
      "q-opt-1.rq(2)" => [
        "{OPTIONAL {<d><e><f>}}",
        %q((leftjoin
          (bgp)
          (bgp (triple <d> <e> <f>))))
      ],
      # From data/Optional/q-opt-2.rq
      "q-opt-2.rq(1)" => [
        "{<a><b><c> OPTIONAL {<d><e><f>} OPTIONAL {<g><h><i>}}",
        %q((leftjoin
            (leftjoin
              (bgp (triple <a> <b> <c>))
              (bgp (triple <d> <e> <f>)))
            (bgp (triple <g> <h> <i>))))
      ],
      "q-opt-2.rq(2)" => [
        "{<a><b><c> {:x :y :z} {<d><e><f>}}",
        %q((join
            (join
              (bgp (triple <a> <b> <c>))
              (bgp (triple <x> <y> <z>)))
            (bgp (triple <d> <e> <f>))))
      ],
      "q-opt-2.rq(3)" => [
        "{<a><b><c> {:x :y :z} <d><e><f>}",
        %q((join
            (join
              (bgp (triple <a> <b> <c>))
              (bgp (triple <x> <y> <z>)))
            (bgp (triple <d> <e> <f>))))
      ],
      # From data/extracted-examples/query-4.1-q1.rq
      "query-4.1-q1.rq(1)" => [
        "{{:x :y :z} {<d><e><f>}}",
        %q((join
            (bgp (triple <x> <y> <z>))
            (bgp (triple <d> <e> <f>))))
      ],
      "query-4.1-q1.rq(2)" => [
        "{<a><b><c> {:x :y :z} UNION {<d><e><f>}}",
        %q((join
            (bgp (triple <a> <b> <c>))
            (union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))))
      ],
      # From data/Optional/q-opt-3.rq
      "q-opt-3.rq(1)" => [
        "{{:x :y :z} UNION {<d><e><f>}}",
        %q((union
            (bgp (triple <x> <y> <z>))
            (bgp (triple <d> <e> <f>))))
      ],
      "q-opt-3.rq(2)" => [
        "{GRAPH ?src { :x :y :z}}",
        %q((graph ?src (bgp (triple <x> <y> <z>))))
      ],
      "q-opt-3.rq(3)" => [
        "{<a><b><c> GRAPH <graph> {<d><e><f>}}",
        %q((join
            (bgp (triple <a> <b> <c>))
            (graph <graph>
              (bgp (triple <d> <e> <f>)))))
      ],
      "q-opt-3.rq(4)" => [
        "{ ?a :b ?c .  OPTIONAL { ?c :d ?e } . FILTER (! bound(?e))}",
        %q((filter (! (bound ?e))
            (leftjoin
              (bgp (triple ?a <b> ?c))
              (bgp (triple ?c <d> ?e)))))
      ],
      # From data/Expr1/expr-2
      "expr-2" => [
        "{ ?book dc:title ?title .
          OPTIONAL
            { ?book x:price ?price .
              FILTER (?price < 15) .
            } .
        }",
        %q((leftjoin (bgp (triple ?book <title> ?title)) (bgp (triple ?book <price> ?price)) (< ?price 15)))
      ],
      # From data-r2/filter-nested-2
      "filter-nested-2(1)" => [
        "{ :x :p ?v . { FILTER(?v = 1) } }",
        %q((join
          (bgp (triple <x> <p> ?v))
          (filter (= ?v 1)
            (bgp))))
      ],
      "filter-nested-2(2)" => [
        "{FILTER (?v = 2) FILTER (?w = 3) ?s :p ?v . ?s :q ?w . }",
        %q((filter (exprlist (= ?v 2) (= ?w 3))
          (bgp
            (triple ?s <p> ?v)
            (triple ?s <q> ?w)
          )))
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end

    include_examples "BGP Patterns", "{%s}"
  end

  describe "when matching the TriplesBlock production rule", production: :TriplesBlock do
    include_examples "BGP Patterns", "%s"
  end

  describe "when matching the GraphPatternNotTriples production rule", production: :GraphPatternNotTriples do
    {
      "empty" => ["", EBNF::LL1::Parser::Error],
      "OptionalGraphPattern" => [
        "OPTIONAL {<d><e><f>}",
        %q((leftjoin (bgp (triple <d> <e> <f>)))),
      ],
      "GroupOrUnionGraphPattern(1)" => [
        "{:x :y :z}",
        %q((bgp (triple <x> <y> <z>))),
      ],
      "GroupOrUnionGraphPattern(2)" => [
        "{:x :y :z} UNION {<d><e><f>}",
        %q((union
            (bgp (triple <x> <y> <z>))
            (bgp (triple <d> <e> <f>)))),
      ],
      "GroupOrUnionGraphPattern(3)" => [
        "{:x :y :z} UNION {<d><e><f>} UNION {?a ?b ?c}",
        %q((union
            (union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))
            (bgp (triple ?a ?b ?c)))),
      ],
      "GraphGraphPattern(1)" => [
        "GRAPH ?a {<d><e><f>}",
        %q((graph ?a (bgp (triple <d> <e> <f>)))),
      ],
      "GraphGraphPattern(2)" => [
        "GRAPH :a {<d><e><f>}",
        %q((graph <a> (bgp (triple <d> <e> <f>)))),
      ],
      "GraphGraphPattern(3)" => [
        "GRAPH <a> {<d><e><f>}",
        %q((graph <a> (bgp (triple <d> <e> <f>)))),
      ],
      "Bind" => [
        "BIND(?o+10 AS ?z)", %q((extend (?z (+ ?o 10)))),
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the OptionalGraphPattern production rule", production: :OptionalGraphPattern do
    {
      "empty" => ["", EBNF::LL1::Parser::Error],
      "OptionalGraphPattern" => [
        "OPTIONAL {<d><e><f>}", %q((leftjoin (bgp (triple <d> <e> <f>)))).to_sym,
      ],
      "optional filter (1)" => [
        "OPTIONAL {?book <price> ?price . FILTER (?price < 15)}",
        %q((leftjoin (bgp (triple ?book <price> ?price)) (< ?price 15))).to_sym,
      ],
      "optional filter (2)" => [
        %q(OPTIONAL {?y <q> ?w . FILTER(?v=2) FILTER(?w=3)}),
        %q((leftjoin (bgp (triple ?y <q> ?w)) (exprlist (= ?v 2) (= ?w 3)))).to_sym,
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  describe "when matching the GraphGraphPattern production rule", production: :GraphGraphPattern do
    {
      "empty" => ["", EBNF::LL1::Parser::Error],
      "var" => [
        "GRAPH ?a {<d><e><f>}", %q((graph ?a (bgp (triple <d> <e> <f>)))),
      ],
      "pname" => [
        "GRAPH :a {<d><e><f>}", %q((graph <a> (bgp (triple <d> <e> <f>)))),
      ],
      "iri" => [
        "GRAPH <a> {<d><e><f>}", %q((graph <a> (bgp (triple <d> <e> <f>)))),
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the Bind production rule", production: :Bind do
    {
      "Expression" => [
        "BIND(?o+10 AS ?z)", %q((extend (?z (+ ?o 10)))),
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the TripleTerm production rule", production: :TripleTerm do
    {
      %[<<( :s :p :o )>>] => %[(qtriple <s> <p> <o>)],
      %[<<( _:s :p _:o )>>] => %[(qtriple ??s <p> ??o)],
      %[<<( ?s :p ?o )>>] => %[(qtriple ?s <p> ?o)],
      %[<<( ?s :p "o" )>>] => %[(qtriple ?s <p> "o")],
      %[<<( :s :p <<( :s1 :p1 :o1)>> )>>] => %[(qtriple <s> <p> (qtriple <s1> <p1> <o1>))],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the TripleTermData production rule", production: :TripleTermData do
    {
      %[<<( :s :p :o )>>] => %[(qtriple <s> <p> <o>)],
      %[<<( :s :p <<( :s1 :p1 :o1)>> )>>] => %[(qtriple <s> <p> (qtriple <s1> <p1> <o1>))],
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the GroupOrUnionGraphPattern production rule", production: :GroupOrUnionGraphPattern do
    {
      "empty" => ["", EBNF::LL1::Parser::Error],
      # From data/Optional/q-opt-3.rq
      "bgp" => [
        "{:x :y :z}", %q((bgp (triple <x> <y> <z>))),
      ],
      "union" => [
        "{:x :y :z} UNION {<d><e><f>}",
        %q((union
            (bgp (triple <x> <y> <z>))
            (bgp (triple <d> <e> <f>)))),
      ],
      "union+union" => [
        "{:x :y :z} UNION {<d><e><f>} UNION {?a ?b ?c}",
        %q((union
            (union
              (bgp (triple <x> <y> <z>))
              (bgp (triple <d> <e> <f>)))
            (bgp (triple ?a ?b ?c)))),
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the Filter production rule", production: :Filter do
    # Can't test against SSE, as filter also requires a BGP or other query operator
    {
      "1" => [
        %(FILTER (1)), [:filter, RDF::Literal(1)]
      ],
      "(1)" => [
        %(FILTER ((1))), [:filter, RDF::Literal(1)]
      ],
      '"foo"' => [
        %(FILTER ("foo")), [:filter, RDF::Literal("foo")]
      ],
      'STR ("foo")' => [
        %(FILTER STR ("foo")), [:filter, SPARQL::Algebra::Expression[:str, RDF::Literal("foo")]]
      ],
      'LANGMATCHES ("foo", "bar")' => [
        %(FILTER LANGMATCHES ("foo", "bar")), [:filter, SPARQL::Algebra::Expression[:langmatches, RDF::Literal("foo"), RDF::Literal("bar")]]
      ],
      "isIRI" => [
        %(FILTER isIRI ("foo")), [:filter, SPARQL::Algebra::Expression[:isIRI, RDF::Literal("foo")]]
      ],
      "REGEX" => [
        %(FILTER REGEX ("foo", "bar")), [:filter, SPARQL::Algebra::Expression[:regex, RDF::Literal("foo"), RDF::Literal("bar")]]
      ],
      "<fun>" => [
        %(FILTER <fun> ("arg")), [:filter, SPARQL::Algebra::Expression[:function_call, RDF::URI("fun"), RDF::Literal("arg")]]
      ],
      "bound" => [
        %(FILTER BOUND (?e)), [:filter, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]]
      ],
      "(bound)" => [
        %(FILTER (BOUND (?e))), [:filter, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]]
      ],
      "!bound" => [
        %(FILTER (! BOUND (?e))), [:filter, SPARQL::Algebra::Expression[:not, SPARQL::Algebra::Expression[:bound, RDF::Query::Variable.new("e")]]]
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: true))
      end
    end
  end

  describe "when matching the Constraint production rule", production: :Constraint do
    include_examples "FunctionCall"
    include_examples "BrackettedExpression"
    include_examples "BuiltInCall"
  end

  describe "when matching the FunctionCall production rule", production: :FunctionCall do
    include_examples "FunctionCall"
  end

  describe "when matching the ArgList production rule", production: :ArgList do
    {
      %q(())             => [RDF["nil"]],
      %q(("foo"))        => [RDF::Literal("foo")],
      %q(("foo", "bar")) => [RDF::Literal("foo"), RDF::Literal("bar")]
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata)
      end
    end
  end

  describe "when matching the ConstructTemplate production rule", production: :ConstructTemplate do
    {
      "syntax-basic-03.rq" => [
        %q(?x ?y ?z),
        RDF::Query.new do
          pattern [RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y"), RDF::Query::Variable.new("z")]
        end
      ],
      "syntax-basic-05.rq" => [
        %q(?x ?y ?z),
        RDF::Query.new do
          pattern [RDF::Query::Variable.new("x"), RDF::Query::Variable.new("y"), RDF::Query::Variable.new("z")]
        end,
      ],
      "syntax-bnodes-01.rq" => [
        %q([:p :q ]),
        RDF::Query.new do
          pattern [RDF::Node.new("b0"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/q")]
        end
      ],
      "syntax-bnodes-02.rq" => [
        %q([] :p :q),
        RDF::Query.new do
          pattern [RDF::Node.new("b0"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/q")]
        end
      ],
      "syntax-general-01.rq" => [
        %q(<a><b><c>),
        RDF::Query.new do
          pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::URI("http://example.org/c")]
        end
      ],
      "syntax-general-02.rq" => [
        %q(<a><b>_:x),
        RDF::Query.new do
          pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Node("x")]
        end
      ],
      "<< :s :p :o >>" => [
        %q(<< :s :p :o >>),
        RDF::Query.new do
          pattern [RDF::Node("b1"), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies"),
            RDF::Statement(RDF::URI("http://example.com/s"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/o"), tripleTerm: true)]
        end
      ],
      "<< :s :p :o ~ >>" => [
        %q(<< :s :p :o ~ >>),
        RDF::Query.new do
          pattern [RDF::Node("b1"), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies"),
            RDF::Statement(RDF::URI("http://example.com/s"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/o"), tripleTerm: true)]
        end
      ],
      "<< :s :p :o ~:r >>" => [
        %q(<< :s :p :o ~:r >>),
        RDF::Query.new do
          pattern [RDF::URI("http://example.com/r"), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies"),
            RDF::Statement(RDF::URI("http://example.com/s"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/o"), tripleTerm: true)]
        end
      ],
      "<< :s :p :o ~_:r >>" => [
        %q(<< :s :p :o ~_:r >>),
        RDF::Query.new do
          pattern [RDF::Node("r"), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies"),
            RDF::Statement(RDF::URI("http://example.com/s"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/o"), tripleTerm: true)]
        end
      ],
      "<< :s :p :o ~:r >> :p2 :o2" => [
        %q(<< :s :p :o ~:r >> :p2 :o2),
        RDF::Query.new do
          pattern [RDF::URI("http://example.com/r"), RDF::URI("http://www.w3.org/1999/02/22-rdf-syntax-ns#reifies"),
            RDF::Statement(RDF::URI("http://example.com/s"), RDF::URI("http://example.com/p"), RDF::URI("http://example.com/o"), tripleTerm: true)]
          pattern [RDF::URI("http://example.com/r"), RDF::URI("http://example.com/p2"), RDF::URI("http://example.com/o2")]
        end
      ],
    }.each do |title, (input, output)|
      it title do |example|
        expect("{#{input}}").to generate((output.patterns),
          example.metadata.merge(
            prefixes: {nil => "http://example.com/", rdf: RDF.to_uri.to_s},
            base_uri: RDF::URI("http://example.org/"),
            anon_base: "b0"))
      end
    end
  end

  # Property paths
  describe "Property Paths [88] Path production rule", production: :Path do
    {
      %(<p>?) => %((path? <p>)),
      %(<p>*) => %((path* <p>)),
      %(<p>+) => %((path+ <p>)),
      %((<p>+)) => %((path+ <p>)),
      %(^<p>) => %((reverse <p>)),
      %(!^<p>) => %((notoneof (reverse <p>))),
      %(<p1>/<p2>) => %((seq <p1> <p2>)),
      %(<p1>|<p2>) => %((alt <p1> <p2>)),
      %(<p1>/<p2>/<p3>) => %((seq (seq <p1> <p2>) <p3>)),
      %(<p1>|<p2>|<p3>) => %((alt (alt <p1> <p2>) <p3>)),
      %((!<p>)+/<name>) => %((seq (path+ (notoneof <p>)) <name>)),
      %(<p1>|(<p2>+/<p3>+)) => %((alt <p1> (seq (path+ <p2>) (path+ <p3>)))),
      %((((<p>)*)*)*) => %((path* (path* (path* <p>)))),
      %(!(:pd|^:pr)) => %((notoneof <pd> (reverse <pr>))),
      %(:p{2}) => %((pathRange 2 2 <p>)),
      %(:p{2,4}) => %((pathRange 2 4 <p>)),
      %(:p{,3}) => %((pathRange 0 3 <p>)),
      %(:p1|:p2/:p3|:p4) => %((alt (alt <p1> (seq <p2> <p3>)) <p4>)),
      %((:p1|:p2)/(:p3|:p4)) => %((seq (alt <p1> <p2>) (alt <p3> <p4>))),
      %(:p0|^:p1/:p2|:p3) => %((alt (alt <p0> (seq (reverse <p1>) <p2>)) <p3>)),
      %((:p0|^:p1)/:p2|:p3) => %((alt (seq (alt <p0> (reverse <p1>)) <p2>) <p3>)),
    }.each do |input, output|
      it input do |example|
        expect(input).to generate(output, example.metadata.merge(resolve_iris: false))
      end
    end
  end

  # Productions that can be tested individually
  describe "individual nonterminal productions" do
    describe "when matching the VarOrTerm production rule", production: :VarOrTerm do
      include_examples "Var"
      include_examples "iri"
      include_examples "RDFLiteral"
      include_examples "NumericLiteral"
      include_examples "BooleanLiteral"
      include_examples "BlankNode"
      include_examples "NIL"
      #include_examples "TripleTerm"
    end

    describe "when matching the VarOrIri production rule", production: :VarOrIri do
      include_examples "Var"
      include_examples "iri"
    end

    describe "when matching the Var production rule", production: :Var do
      include_examples "Var"
    end

    describe "when matching the Expression production rule", production: :Expression do
      include_examples "Expression"
    end

    describe "when matching the ConditionalOrExpression production rule", production: :ConditionalOrExpression do
      include_examples "ConditionalOrExpression"
    end

    describe "when matching the ConditionalAndExpression production rule", production: :ConditionalAndExpression do
      include_examples "ConditionalAndExpression"
    end

    describe "when matching the ValueLogical production rule", production: :ValueLogical do
      include_examples "ValueLogical"
    end

    describe "when matching the RelationalExpression production rule", production: :RelationalExpression do
      include_examples "RelationalExpression"
    end

    describe "when matching the NumericExpression production rule", production: :NumericExpression do
      include_examples "NumericExpression"
    end

    describe "when matching the AdditiveExpression production rule", production: :AdditiveExpression do
      include_examples "AdditiveExpression"
    end

    describe "when matching the MultiplicativeExpression production rule", production: :MultiplicativeExpression do
      include_examples "MultiplicativeExpression"
    end

    describe "when matching the UnaryExpression production rule", production: :UnaryExpression do
      include_examples "UnaryExpression"
    end

    describe "when matching the PrimaryExpression production rule", production: :PrimaryExpression do
      include_examples "PrimaryExpression"
    end

    describe "when matching the BrackettedExpression production rule", production: :BrackettedExpression do
      include_examples "BrackettedExpression"
    end

    describe "when matching the BuiltInCall production rule", production: :BuiltInCall do
      include_examples "BuiltInCall"
    end

    describe "when matching the iriOrFunction production rule", production: :iriOrFunction do
      include_examples "iriOrFunction"
    end

    describe "when matching the RDFLiteral production rule", production: :RDFLiteral do
      include_examples "RDFLiteral"
    end

    describe "when matching the NumericLiteral production rule", production: :NumericLiteral do
      include_examples "NumericLiteral"
    end
  end

  # Individual terminal productions
  describe "individual terminal productions" do
    describe "when matching the iri production rule", production: :iri do
      include_examples "iri"
    end

    describe "when matching the PrefixedName production rule", production: :PrefixedName do
      {
        PNAME_LN: {
          ":bar"    => RDF::URI("http://example.com/bar"),
          "foo:first" => RDF.first
        },
        PNAME_NS: {
          ":"    => RDF::URI("http://example.com/"),
          "foo:" => RDF.to_uri
        }
      }.each do |terminal, examples|
        it "recognizes the #{terminal} terminal" do |example|
          examples.each do |input, result|
            expect(input).to generate(result, example.metadata.merge(
              prefixes: {
                nil => "http://example.com/",
                foo: RDF.to_uri.to_s
              }))
          end
        end
      end
    end

    describe "when matching the BlankNode production rule", production: :BlankNode do
      it "recognizes the BlankNode terminal" do |example|
        if output = parser(example.metadata[:production]).call(%q(_:foobar))
          v = RDF::Query::Variable.new("foobar", distinguished: false)
          expect(output).to eq v
          expect(output).not_to be_distinguished
        end
      end

      it "recognizes the ANON terminal" do |example|
        if output = parser(example.metadata[:production]).call(%q([]))
          expect(output).not_to be_distinguished
        end
      end
    end
  end

  context "issues", production: :QueryUnit do
    {
      issue3: [
        %(
          PREFIX a: <http://localhost/attribute_types/>
          SELECT ?entity
          WHERE {
            ?entity a:first_name 'joe' .
            ?entity a:last_name 'smith' .
            OPTIONAL {
              ?entity a:middle_name 'blah'
            }
          }
        ),
        %q{
          (prefix
           ((a: <http://localhost/attribute_types/>))
           (project
            (?entity)
            (leftjoin
             (bgp (triple ?entity a:first_name "joe") (triple ?entity a:last_name "smith"))
             (bgp (triple ?entity a:middle_name "blah"))) ))
        }
      ],
      issue7: [
        %(
          PREFIX ex: <urn:example#>

          SELECT ?subj ?pred ?obj
          WHERE {
            ?subj ?pred ?obj . {
              { ?subj ex:pred1 ?obj } UNION
              { ?subj ex:pred2 ?obj } UNION
              { ?subj ex:pred3 ?obj } UNION
              { ?subj ex:pred4 ?obj } UNION
              { ?subj ex:pred5 ?obj } UNION
              { ?subj ex:pred6 ?obj } UNION
              { ?subj ex:pred7 ?obj }
            }
          }
        ),
        %{
          (prefix ((ex: <urn:example#>))
            (project (?subj ?pred ?obj)
              (join
                (bgp (triple ?subj ?pred ?obj))
                (union
                  (union
                    (union
                      (union
                        (union
                          (union
                            (bgp (triple ?subj ex:pred1 ?obj))
                            (bgp (triple ?subj ex:pred2 ?obj)))
                          (bgp (triple ?subj ex:pred3 ?obj)))
                        (bgp (triple ?subj ex:pred4 ?obj)))
                      (bgp (triple ?subj ex:pred5 ?obj)))
                    (bgp (triple ?subj ex:pred6 ?obj)))
                  (bgp (triple ?subj ex:pred7 ?obj))))))
        }
      ],
      issue9_short: [
        %q{
          SELECT * WHERE {
            ?subj ?p ?o .
            BIND (?o AS ?v)
            ?o ?p1 "foo" .
            BIND (?p1 AS ?v2)
          }
        },
        %q{
          (extend ((?v2 ?p1))
            (join
              (extend ((?v ?o))
                (bgp (triple ?subj ?p ?o)))
              (bgp (triple ?o ?p1 "foo"))))
        }
      ],
      issue9_short2: [
        %q{
          SELECT * WHERE {
            ?subj ?p ?o .
            BIND (<http://eli.budabe.eu/eli/dir/2010/24/consil/oj> AS ?eli)
            BIND (str(?eli) AS ?eli_str)
            ?o ?p1 "foo" .
            BIND (IRI(?eli) AS ?expr_eli)
            OPTIONAL { 
              ?manif_cellar_id ?p ?manif .
            }
            BIND (?p1 AS ?v2)
          }
        },
        %q{
          (extend ((?v2 ?p1))
            (leftjoin
              (extend ((?expr_eli (iri ?eli)))
                (join
                  (extend ((?eli <http://eli.budabe.eu/eli/dir/2010/24/consil/oj>)
                           (?eli_str (str ?eli)))
                    (bgp (triple ?subj ?p ?o)))
                  (bgp (triple ?o ?p1 "foo"))))
              (bgp (triple ?manif_cellar_id ?p ?manif))))
        }
      ],
      issue21: [
        %q{
          PREFIX ext:<http://ext.com/1.0#>
          PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

          SELECT *
          WHERE {?x a ext:Subject; ?prop ?obj}
        },
        %q{
          (prefix
           ((ext: <http://ext.com/1.0#>) (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>))
           (bgp (triple ?x a ext:Subject) (triple ?x ?prop ?obj)))
        }
      ],
      issue30: [
        %q{
          PREFIX ns:<http://ns.com>
          CONSTRUCT {?item ns:link ?target}
          WHERE {
            ?item ?link ?wrapper .
            {?item ?p ?wrapper .}
            ?item ns:slot / ns:item ?target .
          }
        },
        %q{
          (prefix
           ((ns: <http://ns.com>))
           (construct ((triple ?item ns:link ?target))
            (sequence
             (join
              (bgp (triple ?item ?link ?wrapper))
              (bgp (triple ?item ?p ?wrapper)))
             (path ?item (seq ns:slot ns:item) ?target))))
        }
      ],
      issue32: [
        %q{
          SELECT * WHERE {
              ?s ?p ?o
              VALUES ?s { } # Notice the empty values list
          }
        },
        %q{
          (join
            (bgp (triple ?s ?p ?o))
            (table (vars ?s)))
        }
      ],
      issue43: [
        %q{
          SELECT * { 
              :x1 :p ?v .
              OPTIONAL
              {
                :x3 :q ?w .
                OPTIONAL { :x2 :p ?v }
              }
          }
        },
        %q{
          (project ()
           (leftjoin
            (bgp (triple <x1> <p> ?v))
            (leftjoin
             (bgp (triple <x3> <q> ?w))
             (bgp (triple <x2> <p> ?v)))))
        },
        {all_vars: true}
      ],
    }.each do |title, (input, result, options)|
      it title do |example|
        expect(input).to generate(result, example.metadata.merge(resolve_iris: false).merge(options || {}))
      end
    end
  end

  def parser(production = nil, **options)
    @logger = options.fetch(:logger, RDF::Spec.logger)
    Proc.new do |query|
      parser = described_class.new(query, all_vars: true, logger: @logger, resolve_iris: true, **options)
      production ? parser.parse(production) : parser
    end
  end
end
