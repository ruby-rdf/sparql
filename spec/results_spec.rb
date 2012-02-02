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
          s = RDF::Query::Solutions.new << (r[:solution].is_a?(Hash) ? RDF::Query::Solution.new(r[:solution]) : r[:solution])
          s.to_json.should == r[:json].to_json
        end
      end
    end
    
    describe "#to_xml" do
      SOLUTIONS.each do |n, r|
        describe "encoding #{n}" do
          r[:xml].each do |(xp, value)|
            it "has xpath #{xp} = #{value.inspect}" do
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
            it "has xpath #{xp} = #{value.inspect}" do
              s = RDF::Query::Solutions.new << RDF::Query::Solution.new(r[:solution])
          
              s.to_html.should have_xpath(xp, value)
            end
          end
        end
      end
    end
  end
  
  describe "#serialize_results" do
    context "boolean" do
      BOOLEAN = {
        :true          => { :value    => true,
                           :json     => {:boolean => true},
                           :xml      => [
                             ["/sr:sparql/sr:boolean/text()", "true"],
                           ],
                           :html     => [
                             ["/div[@class='sparql']/text()", "true"],
                           ],
                          },
        :false         => { :value    => false,
                           :json     => {:boolean => false},
                           :xml      => [
                             ["/sr:sparql/sr:boolean/text()", "false"],
                           ],
                           :html     => [
                             ["/div[@class='sparql']/text()", "false"],
                           ],
                          },
        :rdf_true      => { :value    => RDF::Literal::TRUE,
                           :json     => {:boolean => true},
                           :xml      => [
                             ["/sr:sparql/sr:boolean/text()", "true"],
                           ],
                           :html     => [
                             ["/div[@class='sparql']/text()", "true"],
                           ],
                          },
        :rdf_false     => { :value    => RDF::Literal::FALSE,
                           :json     => {:boolean => false},
                           :xml      => [
                             ["/sr:sparql/sr:boolean/text()", "false"],
                           ],
                           :html     => [
                             ["/div[@class='sparql']/text()", "false"],
                           ],
                          },
      }

      context "json" do
        BOOLEAN.each do |n, r|
          describe "encoding #{n}" do
            subject {SPARQL.serialize_results(r[:value], :format => :json)}
            it "uses :format => :json" do
              subject.should == r[:json].to_json
            end

            it "uses using :content_type => 'application/sparql-results+json'" do
              s = SPARQL.serialize_results(r[:value], :content_type => 'application/sparql-results+json')
              s.should == subject
            end

            it "returns 'application/sparql-results+json' for #content_type" do
              subject.content_type.should == 'application/sparql-results+json'
            end
          end
        end
      end
      
      context "xml" do
        BOOLEAN.each do |n, r|
          describe "encoding #{n}" do
            r[:xml].each do |(xp, value)|
              subject {SPARQL.serialize_results(r[:value], :format => :xml)}
              it "has xpath #{xp} = #{value.inspect} using :format => :xml" do
                subject.should have_xpath(xp, value)
              end

              it "has xpath #{xp} = #{value.inspect} using :content_type => 'application/sparql-results+xml'" do
                s = SPARQL.serialize_results(r[:value], :content_type => 'application/sparql-results+xml')
                s.should == subject
              end
              
              it "returns 'application/sparql-results+xml' for #content_type" do
                subject.content_type.should == 'application/sparql-results+xml'
              end
            end
          end
        end
      end
      
      context "html" do
        BOOLEAN.each do |n, r|
          describe "encoding #{n}" do
            r[:html].each do |(xp, value)|
              subject {SPARQL.serialize_results(r[:value], :format => :html)}
              it "has xpath #{xp} using :format => :html" do
                subject.should have_xpath(xp, value)
              end

              it "has xpath #{xp} using :content_type => 'text/html'" do
                s = SPARQL.serialize_results(r[:value], :content_type => 'text/html')
                s.should == subject
              end
              
              it "returns 'text/html' for #content_type" do
                subject.content_type.should == 'text/html'
              end
            end
          end
        end
      end
    end

    context "graph" do
      {
        :ntriples => 'text/plain',
        :n3       => 'text/rdf+n3',
      }.each do |format, content_type|
        context "with format #{format}" do
          before(:each) do
            @solutions = mock("Solutions")
            @solutions.extend(RDF::Queryable)
            fmt = mock("Format")
            writer = mock("Writer")
            buffer = mock("Buffer")
            RDF::Format.should_receive(:for).at_least(1).times.and_return(fmt)
            fmt.should_receive(:content_types).and_return([content_type])
            fmt.should_receive(:writer).at_least(1).times.and_return(writer)
            fmt.stub!(:to_sym).and_return(format)
            writer.should_receive(:buffer).at_least(1).times.and_return(buffer)
            buffer.should_receive(:<<).at_least(1).times.with(@solutions).and_return("serialized graph")
          end

          subject {SPARQL.serialize_results(@solutions, :format => format)}

          it "serializes graph with format #{format.inspect}" do
            subject.should == "serialized graph"
          end

          it "serializes graph with content_type #{content_type}" do
            s = SPARQL.serialize_results(@solutions, :content_type => content_type)
            s.should == subject
          end
      
          it "returns #{content_type} for #content_type" do
            subject.content_type.should == content_type
          end
        end
      end
    end
    
    context "solutions" do
      SPARQL::Results::MIME_TYPES.each do |format, content_type|
        context "with format #{format}" do
          before(:each) do
            @solutions = RDF::Query::Solutions.new
          end
          
          it "serializes results wihth format #{format.inspect}" do
            @solutions.should_receive("to_#{format}").and_return("serialized results")
            s = SPARQL.serialize_results(@solutions, :format => format)
            s.should == "serialized results"
            s.content_type.should == content_type
          end
        end
      end
    end
  end
  
  describe "#serialize_exception" do
    [{:format => :html}, {:content_type => "text/html"}].each do |options|
      context "with options #{options.inspect}" do
        {
          SPARQL::MalformedQuery      => "Malformed Query",
          SPARQL::QueryRequestRefused => "Query Request Refused",
          RuntimeError                => "RuntimeError"
        }.each do |cls, title|
          context "for #{cls}" do
            subject { SPARQL.serialize_exception(cls.new("error string"), options)}

            [
              ['/html/head/title/text()', "SPARQL Processing Service: #{title}"],
              ['/html/body/p/text()', "#{title}: error string"],
            ].each do |(xp, value)|
              it "has xpath #{xp} = #{value.inspect}" do
                subject.should have_xpath(xp, value)
              end
            
              it "has content_type text/html" do
                subject.content_type.should == 'text/html'
              end
            end
          end
        end
      end
    end

    [{:format => :xml}, {:content_type => "application/sparql-results+xml"}, {}].each do |options|
      context "with options #{options.inspect}" do
        {
          SPARQL::MalformedQuery      => "Malformed Query",
          SPARQL::QueryRequestRefused => "Query Request Refused",
          RuntimeError                => "RuntimeError"
        }.each do |cls, title|
          context "for #{cls}" do
            subject { SPARQL.serialize_exception(cls.new("error string"), options)}

            it "has simple error string" do
              subject.should == "error string"
            end

            it "has content_type text/plain" do
              subject.content_type.should == 'text/plain'
            end
          end
        end
      end
    end
  end
end