$:.unshift "."
require 'spec_helper'

describe SPARQL::Results do
  describe RDF::Query::Solutions do
    SOLUTIONS = {
      :uri           => {:solution => {:a => RDF::URI("a")},
                         :json     => {
                           :head => {:vars => ["a"]},
                           :results => {:bindings => [{"a" => {:type => "uri", :value => "a" }}]}
                         },
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:uri/text()", "a"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                           ["/table[@class='sparql']/tbody/tr/td/text()", "&lt;a&gt;"],
                         ],
                        },
      :node          => {:solution => {:a => RDF::Node.new("a")},
                         :json     => {
                           :head => {:vars => ["a"]},
                           :results => {:bindings => [{"a" => {:type => "bnode", :value => "a" }}]}
                         },
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:bnode/text()", "a"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                           ["/table[@class='sparql']/tbody/tr/td/text()", "_:a"],
                         ],
                        },
      :literal_plain => {:solution => {:a => RDF::Literal("a")},
                         :json     => {
                           :head => {:vars => ["a"]},
                           :results => {:bindings => [{"a" => {:type => "literal", :value => "a" }}]}
                         },
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:literal/text()", "a"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                           ["/table[@class='sparql']/tbody/tr/td/text()", '"a"'],
                         ],
                        },
      :literal_lang  => {:solution => {:a => RDF::Literal("a", :language => :en)},
                         :json     => {
                           :head => {:vars => ["a"]},
                           :results => {:bindings => [{"a" => {:type => "literal", "xml:lang" => "en", :value => "a" }}]}
                         },
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:literal[@xml:lang='en']/text()", "a"],
                          ],
                          :html     => [
                            ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                            ["/table[@class='sparql']/tbody/tr/td/text()", '"a"@en'],
                          ],
                        },
      :literal_dt    => {:solution => {:a => RDF::Literal(1)},
                         :json     => {
                           :head => {:vars => ["a"]},
                           :results => {:bindings => [{"a" => {:type => "literal", "datatype" => RDF::XSD.integer.to_s, :value => "1" }}]}
                         },
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:literal[@datatype='#{RDF::XSD.integer}']/text()", "1"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                           ["/table[@class='sparql']/tbody/tr/td/text()", %("1"^^&lt;#{RDF::XSD.integer}&gt;)],
                         ],
                        },
    }
    describe "#to_json" do
      SOLUTIONS.each do |n, r|
        it "encodes a #{n}" do
          s = RDF::Query::Solutions.new << RDF::Query::Solution.new(r[:solution])
          s.to_json.should == r[:json].to_json
        end
      end
    end
    
    describe "#to_xml" do
      SOLUTIONS.each do |n, r|
        describe "encoding #{n}" do
          r[:xml].each do |(xp, value)|
            it "has xpath #{xp}" do
              s = RDF::Query::Solutions.new << RDF::Query::Solution.new(r[:solution])
          
              s.to_xml.should have_xpath(xp, value)
            end
          end
        end
      end
    end
    
    describe "#to_html" do
      SOLUTIONS.each do |n, r|
        describe "encoding #{n}" do
          r[:html].each do |(xp, value)|
            it "has xpath #{xp}" do
              s = RDF::Query::Solutions.new << RDF::Query::Solution.new(r[:solution])
          
              s.to_html.should have_xpath(xp, value)
            end
          end
        end
      end
    end
  end
  
  describe "#serialize_results" do
  end
  
  describe "#serialize_exception" do
  end
end