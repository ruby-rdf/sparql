$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'nokogiri'
require 'equivalent-xml'

describe "SPARQL-star" do
  let(:data) do
    RDF::Graph.new do |g|
      g << RDF::NTriples::Reader.new(%(
        <http://bigdata.com/bob> <http://xmlns.com/foaf/0.1/name> "Bob" .
        <http://bigdata.com/bob> <http://xmlns.com/foaf/0.1/age> "23"^^<http://www.w3.org/2001/XMLSchema#integer> .
        <<<http://bigdata.com/bob> <http://xmlns.com/foaf/0.1/age> "23"^^<http://www.w3.org/2001/XMLSchema#integer>>> <http://example.org/certainty> "0.9"^^<http://www.w3.org/2001/XMLSchema#decimal> .
      ), rdfstar: true)
    end
  end

  {
    "Base Query": {
      query: %(
        PREFIX : <http://bigdata.com/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        PREFIX ex:  <http://example.org/>

        SELECT ?age ?c WHERE {
           ?bob foaf:name "Bob" .
           <<?bob foaf:age ?age>> ex:certainty ?c .
        }
      ),
      result: {
        sxp: %(
          (prefix ((: <http://bigdata.com/>)
            (foaf: <http://xmlns.com/foaf/0.1/>)
            (ex: <http://example.org/>))
          (project
           (?age ?c)
           (bgp
            (triple ?bob foaf:name "Bob")
            (triple (qtriple ?bob foaf:age ?age) ex:certainty ?c)) ))),
        json: JSON.parse(%({
          "head": {"vars": ["age", "c"]},
          "results": {
            "bindings": [{
              "age": {"type": "typed-literal", "value": "23", "datatype": "http://www.w3.org/2001/XMLSchema#integer"},
              "c": {"type": "typed-literal", "value": "0.9", "datatype": "http://www.w3.org/2001/XMLSchema#decimal"}
            }]
          }
        })),
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="UTF-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
            <head>
              <variable name="age"/>
              <variable name="c"/>
            </head>
            <results>
              <result>
                <binding name="age">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#integer">23</literal>
                </binding>
                <binding name="c">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#decimal">0.9</literal>
                </binding>
              </result>
            </results>
          </sparql>)),
        csv: %(age,c\r\n23,0.9\r\n),
        tsv: %(?age\t?c\r\n23\t0.9\r\n),
      }
    },
    "Base Query (annotation syntax)": {
      query: %(
        PREFIX : <http://bigdata.com/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        PREFIX ex:  <http://example.org/>
    
        SELECT ?age ?c WHERE {
          ?bob foaf:name "Bob" .
           ?bob foaf:age ?age {| ex:certainty ?c |}.
        }
      ),
      result: {
        sxp: %(
          (prefix ((: <http://bigdata.com/>)
            (foaf: <http://xmlns.com/foaf/0.1/>)
            (ex: <http://example.org/>))
          (project
           (?age ?c)
           (bgp
            (triple ?bob foaf:name "Bob")
            (triple ?bob foaf:age ?age)
            (triple (qtriple ?bob foaf:age ?age) ex:certainty ?c)) ))),
        json: JSON.parse(%({
          "head": {"vars": ["age", "c"]},
          "results": {
            "bindings": [{
              "age": {"type": "typed-literal", "value": "23", "datatype": "http://www.w3.org/2001/XMLSchema#integer"},
              "c": {"type": "typed-literal", "value": "0.9", "datatype": "http://www.w3.org/2001/XMLSchema#decimal"}
            }]
          }
        })),
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="UTF-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
            <head>
              <variable name="age"/>
              <variable name="c"/>
            </head>
            <results>
              <result>
                <binding name="age">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#integer">23</literal>
                </binding>
                <binding name="c">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#decimal">0.9</literal>
                </binding>
              </result>
            </results>
          </sparql>)),
        csv: %(age,c\r\n23,0.9\r\n),
        tsv: %(?age\t?c\r\n23\t0.9\r\n),
      }
    },
    "sparql-star-annotation-06": {
      query: %(
        PREFIX : <http://example.com/ns#>

        SELECT * {
          ?s ?p ?o {| :r/:q 'ABC' |} .
        }
      ),
      result: {
        sxp: %{
          (prefix ((: <http://example.com/ns#>))
           (join
            (bgp (triple ?s ?p ?o))
            (path ((qtriple ?s ?p ?o)) (seq :r :q) "ABC")))
        }
      }
    },
    "sparql-star-annotation-08": {
      query: %(
        PREFIX : <http://example.com/ns#>

        CONSTRUCT { ?s ?p ?o {| :source ?g |} }
        WHERE { GRAPH ?g { ?s ?p ?o } }
      ),
      result: {
        sxp: %{
          (prefix ((: <http://example.com/ns#>))
           (construct
            ((triple (qtriple ?s ?p ?o) :source ?g)
             (triple ?s ?p ?o))
            (graph ?g (bgp (triple ?s ?p ?o)))) )
        }
      }
    },
    "sparql-star-syntax-expr-04": {
      query: %(
        PREFIX : <http://example.com/ns#>

        SELECT * {
          ?s ?p ?o .
          BIND(TRIPLE(?s, ?p, str(?o)) AS ?t2)
        }
      ),
      result: {
        sxp: %{
          (prefix ((: <http://example.com/ns#>))
           (extend
            ((?t2 (triple ?s ?p (str ?o))))
            (bgp (triple ?s ?p ?o))))
        }
      }
    },
    "sparql-star-syntax-update-2": {
      query: %(
        PREFIX : <http://example.com/ns#>

        INSERT DATA { :s :p :o {| :y :z |} }
      ),
      update: true,
      result: {
        sxp: %{
          (prefix ((: <http://example.com/ns#>))
           (update
            (insertData
             ((triple (qtriple :s :p :o) :y :z)
             (triple :s :p :o)))))
        }
      }
    },
    "sparql-star-syntax-update-4": {
      query: %(
        PREFIX : <http://example.com/ns#>

        INSERT {
            << :a :b :c >> ?P :o2  {| ?Y <<:s1 :p1 ?Z>> |}
        } WHERE {
           << :a :b :c >> ?P :o1 {| ?Y <<:s1 :p1 ?Z>> |}
        }
      ),
      update: true,
      result: {
        sxp: %{
          (prefix ((: <http://example.com/ns#>))
           (update
            (modify
             (bgp
              (triple (qtriple :a :b :c) ?P :o1)
              (triple (qtriple (qtriple :a :b :c) ?P :o1) ?Y (qtriple :s1 :p1 ?Z)))
             (insert
              (
               (triple (qtriple (qtriple :a :b :c) ?P :o2) ?Y (qtriple :s1 :p1 ?Z))
               (triple (qtriple :a :b :c) ?P :o2))))))
        }
      }
    }
  }.each do |name, params|
    context name do
      let(:query) { SPARQL.parse(params[:query], update: params[:update]) }
      let(:result) { data.query(query) }
      subject {result}

      describe "parses to SXP" do
        it "has the same number of triples" do
          q_sxp = query.to_sxp
          unquoted_count = q_sxp.split('(triple').length - 1
          result_count = params[:result][:sxp].split('(triple').length - 1
          expect(unquoted_count).to produce(result_count, [q_sxp])
        end

        it "has the same number of qtriples" do
          q_sxp = query.to_sxp
          quoted_count = q_sxp.split('(qtriple').length - 1
          result_count = params[:result][:sxp].split('(qtriple').length - 1
          expect(quoted_count).to produce(result_count, [q_sxp])
        end

        it "produces equivalent SXP" do
          expect(query).to produce(SPARQL::Algebra.parse(params[:result][:sxp]), [])
        end
      end

      it "generates JSON results" do
        expect(JSON.parse(subject.to_json)).to eql params[:result][:json]
      end if params[:result][:json]

      it "generates XML results" do
        expect(Nokogiri::XML.parse(subject.to_xml)).to be_equivalent_to(params[:result][:xml])
      end if params[:result][:xml]

      it "generates CSV results" do
        expect(subject.to_csv).to be_equivalent_to(params[:result][:csv])
      end if params[:result][:csv]

      it "generates TSV results" do
        expect(subject.to_tsv).to be_equivalent_to(params[:result][:tsv])
      end if params[:result][:tsv]
    end
  end
end