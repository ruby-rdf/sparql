$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'nokogiri'
require 'equivalent-xml'

# See https://github.com/w3c/sparql-12/blob/main/SEP/SEP-0002/sep-0002.md
describe "SEP-003" do
  let!(:data) do
    RDF::Graph.new << RDF::Turtle::Reader.new(%(
      prefix : <http://example/> 
      prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

      :a rdf:first :a0; rdf:rest rdf:nil .
      
      :a rdf:first :b0; rdf:rest :lb1 .
      :lb1 rdf:first :b1; rdf:rest rdf:nil .
      
      :a rdf:first :c0; rdf:rest :lc1 .
      :lc1 rdf:first :c1; rdf:rest :lc2 .
      :lc2 rdf:first :c2; rdf:rest rdf:nil .
      
      :a rdf:first :d0; rdf:rest :ld1 .
      :ld1 rdf:first :d1; rdf:rest :ld2 .
      :ld2 rdf:first :d2; rdf:rest :ld3 .
      :ld3 rdf:first :d3; rdf:rest rdf:nil .
    ))
  end

  {
    "path{0}": {
      query: %(
        prefix : <http://example/> 
        prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select * where {
            :a rdf:rest{0}/rdf:first ?z
        }
      ),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="UTF-8"?>
        <sparql xmlns="http://www.w3.org/2005/sparql-results#">
        <head>
          <variable name="z"/>
        </head>
        <results>
          <result><binding name="z"><uri>http://example/a0</uri></binding></result>
          <result><binding name="z"><uri>http://example/b0</uri></binding></result>
          <result><binding name="z"><uri>http://example/c0</uri></binding></result>
          <result><binding name="z"><uri>http://example/d0</uri></binding></result>
        </results>
        </sparql>)),
      }
    },
    "path{,2}": {
      query: %(
        prefix : <http://example/> 
        prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select * where {
            :a rdf:rest{,2}/rdf:first ?z
        }
      ),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
          <head>
            <variable name="z"/>
          </head>
          <results>
            <result><binding name="z"><uri>http://example/a0</uri></binding></result>
            <result><binding name="z"><uri>http://example/b0</uri></binding></result>
            <result><binding name="z"><uri>http://example/b1</uri></binding></result>
            <result><binding name="z"><uri>http://example/c0</uri></binding></result>
            <result><binding name="z"><uri>http://example/c1</uri></binding></result>
            <result><binding name="z"><uri>http://example/c2</uri></binding></result>
            <result><binding name="z"><uri>http://example/d0</uri></binding></result>
            <result><binding name="z"><uri>http://example/d1</uri></binding></result>
            <result><binding name="z"><uri>http://example/d2</uri></binding></result>
          </results>
          </sparql>))
      }
    },
    "path{1,2}": {
      query: %(
        prefix : <http://example/> 
        prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select * where {
            :a rdf:rest{1,2}/rdf:first ?z
        }
      ),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
          <head>
            <variable name="z"/>
          </head>
          <results>
            <result><binding name="z"><uri>http://example/b1</uri></binding></result>
            <result><binding name="z"><uri>http://example/c1</uri></binding></result>
            <result><binding name="z"><uri>http://example/c2</uri></binding></result>
            <result><binding name="z"><uri>http://example/d1</uri></binding></result>
            <result><binding name="z"><uri>http://example/d2</uri></binding></result>
          </results>
          </sparql>))
      }
    },
    "path{1,}": {
      query: %(
        prefix : <http://example/> 
        prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select * where {
            :a rdf:rest{1,}/rdf:first ?z
        }
      ),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
          <head>
            <variable name="z"/>
          </head>
          <results>
            <result><binding name="z"><uri>http://example/b1</uri></binding></result>
            <result><binding name="z"><uri>http://example/c1</uri></binding></result>
            <result><binding name="z"><uri>http://example/c2</uri></binding></result>
            <result><binding name="z"><uri>http://example/d1</uri></binding></result>
            <result><binding name="z"><uri>http://example/d2</uri></binding></result>
            <result><binding name="z"><uri>http://example/d3</uri></binding></result>
          </results>
          </sparql>))
      }
    },
    "path{2}": {
      query: %(
        prefix : <http://example/> 
        prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

        select * where {
            :a rdf:rest{2}/rdf:first ?z
        }
      ),
      result: {
        xml: Nokogiri::XML.parse(%(<?xml version="1.0" encoding="utf-8"?>
          <sparql xmlns="http://www.w3.org/2005/sparql-results#">
          <head>
            <variable name="z"/>
          </head>
          <results>
            <result><binding name="z"><uri>http://example/c2</uri></binding></result>
            <result><binding name="z"><uri>http://example/d2</uri></binding></result>
          </results>
          </sparql>))
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