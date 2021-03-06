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
            (triple (triple ?bob foaf:age ?age) ex:certainty ?c)) ))),
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
            (triple (triple ?bob foaf:age ?age) ex:certainty ?c)) ))),
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
  }.each do |name, params|
    context name do
      let(:query) {SPARQL.parse(params[:query])}
      let(:result) do
        data.query(query)
      end
      subject {result}

      it "parses to SXP" do
        expect(query).to produce(SPARQL::Algebra.parse(params[:result][:sxp]), [])
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