$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'nokogiri'
require 'equivalent-xml'

# See https://github.com/w3c/sparql-12/blob/main/SEP/SEP-0002/sep-0002.md
describe "SEP-002" do
  let(:data) do
    RDF::Graph.new
  end

  {
    "compare_dayTimeDuration-01": {
      query: %(
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        SELECT ?id ?lt ?gt WHERE {
          VALUES (?id ?l ?r) {
            (1 "PT1H"^^xsd:dayTimeDuration "PT63M"^^xsd:dayTimeDuration)
            (2 "PT3S"^^xsd:dayTimeDuration "PT2M"^^xsd:dayTimeDuration)
            (3 "-PT1H1M"^^xsd:dayTimeDuration "-PT62M"^^xsd:dayTimeDuration)
            (4 "PT0S"^^xsd:dayTimeDuration "-PT0.1S"^^xsd:dayTimeDuration)
          }
          BIND(?l < ?r AS ?lt)
          BIND(?l > ?r AS ?gt)
        }
      ),
      result: {
        json: JSON.parse(%({
          "head": {"vars": ["id", "lt", "gt"]},
          "results": {
            "bindings": [
              {
                "id": {"datatype": "http://www.w3.org/2001/XMLSchema#integer", "type": "typed-literal", "value": "1"},
                "lt": {"datatype": "http://www.w3.org/2001/XMLSchema#boolean", "type": "typed-literal", "value": "true"},
                "gt": {"datatype": "http://www.w3.org/2001/XMLSchema#boolean", "type": "typed-literal", "value": "false"}
              }, {
                "id": {"datatype": "http://www.w3.org/2001/XMLSchema#integer", "type": "typed-literal", "value": "2"},
                "lt": {"datatype": "http://www.w3.org/2001/XMLSchema#boolean", "type": "typed-literal", "value": "true"},
                "gt": {"datatype": "http://www.w3.org/2001/XMLSchema#boolean", "type": "typed-literal", "value": "false"}
              }, {
                "id": {"datatype": "http://www.w3.org/2001/XMLSchema#integer", "type": "typed-literal", "value": "3"},
                "lt": {"datatype": "http://www.w3.org/2001/XMLSchema#boolean", "type": "typed-literal", "value": "false"},
                "gt": {"datatype": "http://www.w3.org/2001/XMLSchema#boolean", "type": "typed-literal", "value": "true"}
              }, {
               "id": {"datatype": "http://www.w3.org/2001/XMLSchema#integer", "type": "typed-literal", "value": "4"},
               "lt": {"datatype": "http://www.w3.org/2001/XMLSchema#boolean", "type": "typed-literal", "value": "false"},
               "gt": {"datatype": "http://www.w3.org/2001/XMLSchema#boolean", "type": "typed-literal", "value": "true"}
              }
            ]
          }
        })),
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="UTF-8"?>
        <sparql xmlns="http://www.w3.org/2005/sparql-results#">
        <head>
          <variable name="id"/>
          <variable name="lt"/>
          <variable name="gt"/>
        </head>
        <results>
            <result>
              <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">1</literal></binding>
              <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
            </result>
            <result>
              <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">2</literal></binding>
              <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
            </result>
            <result>
              <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">3</literal></binding>
              <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
              <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
            </result>
            <result>
              <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">4</literal></binding>
              <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
              <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
            </result>
        </results>
        </sparql>)),
      }
    },
    "compare_duration-01": {
      query: %(PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        SELECT ?id ?eq WHERE {
          VALUES (?id ?l ?r) {
            (1 "P1Y"^^xsd:duration "P1Y"^^xsd:duration)
            (2 "P1Y"^^xsd:duration "P12M"^^xsd:duration)
            (3 "P1Y"^^xsd:duration "P365D"^^xsd:duration)
            (4 "P0Y"^^xsd:duration "PT0S"^^xsd:duration)
            (5 "P1D"^^xsd:duration "PT24H"^^xsd:duration)
            (6 "P1D"^^xsd:duration "PT23H"^^xsd:duration)
            (7 "PT1H"^^xsd:duration "PT60M"^^xsd:duration)
            (8 "PT1H"^^xsd:duration "PT3600S"^^xsd:duration)
            (9 "-P1Y"^^xsd:duration "P1Y"^^xsd:duration)
            (10 "-P0Y"^^xsd:duration "PT0S"^^xsd:duration)
          }
          BIND(?l = ?r AS ?eq)
        }),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
          <head>
            <variable name="id"/>
            <variable name="eq"/>
          </head>
          <results>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">1</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">2</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">3</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">4</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">5</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">6</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">7</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">8</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">9</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">10</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
          </results>
          </sparql>))
      }
    },
    "time-01": {
      query: %(PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        SELECT ?id ?eq ?lt ?gt WHERE {
          VALUES (?id ?l ?r) {
            (1 "00:00:00"^^xsd:time "00:00:00"^^xsd:time)
            (2 "00:00:00"^^xsd:time "00:00:01"^^xsd:time)
            (3 "00:00:02"^^xsd:time "00:00:01"^^xsd:time)
            (4 "10:00:00"^^xsd:time "00:59:01"^^xsd:time)
            (5 "00:00:00"^^xsd:time "24:00:00"^^xsd:time)
          }
          BIND(?l < ?r AS ?lt)
          BIND(?l > ?r AS ?gt)
          BIND(?l = ?r AS ?eq)
        }),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
          <head>
            <variable name="id"/>
            <variable name="eq"/>
            <variable name="lt"/>
            <variable name="gt"/>
          </head>
          <results>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">1</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
                <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">2</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
                <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">3</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">4</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
              </result>
              <result>
                <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">5</literal></binding>
                <binding name="eq"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
                <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
              </result>
          </results>
          </sparql>
          ))
      },
      "compare_yearMonthDuration-01": {
        query: %(
          PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
          SELECT ?id ?lt ?gt WHERE {
            VALUES (?id ?l ?r) {
              (1 "P1Y"^^xsd:yearMonthDuration "P1Y"^^xsd:yearMonthDuration)
              (2 "P1Y"^^xsd:yearMonthDuration "P12M"^^xsd:yearMonthDuration)
              (3 "P1Y1M"^^xsd:yearMonthDuration "P12M"^^xsd:yearMonthDuration)
              (4 "P1M"^^xsd:yearMonthDuration "-P2M"^^xsd:yearMonthDuration)
              (5 "-P1Y"^^xsd:yearMonthDuration "P13M"^^xsd:yearMonthDuration)
            }
            BIND(?l < ?r AS ?lt)
            BIND(?l > ?r AS ?gt)
          }),
        result: {
          xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
            <sparql xmlns="http://www.w3.org/2005/sparql-results#">
            <head>
              <variable name="id"/>
              <variable name="lt"/>
              <variable name="gt"/>
            </head>
            <results>
                <result>
                  <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">1</literal></binding>
                  <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                  <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                </result>
                <result>
                  <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">2</literal></binding>
                  <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                  <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                </result>
                <result>
                  <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">3</literal></binding>
                  <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                  <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
                </result>
                <result>
                  <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">4</literal></binding>
                  <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                  <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
                </result>
                <result>
                  <binding name="id"><literal datatype="http://www.w3.org/2001/XMLSchema#integer">5</literal></binding>
                  <binding name="lt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">true</literal></binding>
                  <binding name="gt"><literal datatype="http://www.w3.org/2001/XMLSchema#boolean">false</literal></binding>
                </result>
            </results>
            </sparql>
            ))
        }
      }
    },
    "construct_date-01": {
      query: %(
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        SELECT (xsd:date(?literal) AS ?date) WHERE {
          VALUES ?literal {
            "2000-11-02"
          }
        }
      ),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
        <sparql xmlns="http://www.w3.org/2005/sparql-results#">
        <head>
          <variable name="date"/>
        </head>
        <results>
            <result>
              <binding name="date"><literal datatype="http://www.w3.org/2001/XMLSchema#date">2000-11-02</literal></binding>
            </result>
        </results>
        </sparql>
        ))
      }
    },
    "construct_duration-02": {
      query: %(
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        SELECT (xsd:duration(?literal) AS ?duration) WHERE {
          VALUES ?literal {
            "P"
            "-P"
            "PT"
            "-PT"
            "PS"
            ""
            "T1S"
          }
        }
      ),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
        <sparql xmlns="http://www.w3.org/2005/sparql-results#">
        <head>
          <variable name="duration"/>
        </head>
        <results>
            <result></result>
            <result></result>
            <result></result>
            <result></result>
            <result></result>
            <result></result>
            <result></result>
        </results>
        </sparql>
        ))
      }
    },
    "construct_time-01": {
      query: %(
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        SELECT (xsd:time(?literal) AS ?time) WHERE {
          VALUES ?literal {
            "00:00:00"
            "24:00:00"
            "01:02:03"
            "23:59:60"
          }
        }
      ),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
          <head>
            <variable name="time"/>
          </head>
          <results>
              <result>
                <binding name="time"><literal datatype="http://www.w3.org/2001/XMLSchema#time">00:00:00</literal></binding>
              </result>
              <result>
                <binding name="time"><literal datatype="http://www.w3.org/2001/XMLSchema#time">00:00:00</literal></binding>
              </result>
              <result>
                <binding name="time"><literal datatype="http://www.w3.org/2001/XMLSchema#time">01:02:03</literal></binding>
              </result>
              <result>
                <binding name="time"><literal datatype="http://www.w3.org/2001/XMLSchema#time">23:59:60</literal></binding>
              </result>
          </results>
          </sparql>
        ))
      }
    },
  }.each do |name, params|
    context name do
      let(:query) { SPARQL.parse(params[:query], update: params[:update]) }
      let(:result) { data.query(query) }
      subject {result}

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