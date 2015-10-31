$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'linkeddata'
require 'csv'

describe SPARQL::Results do
  describe RDF::Query::Solutions do
    SOLUTIONS = {
      :uri           => {solution: [{a: RDF::URI("a")}],
                         :json     => {
                           head: {vars: ["a"]},
                           results: {bindings: [{"a" => {type: "uri", value: "a" }}]}
                         },
                         csv: %(a\r\na\r\n),
                         tsv: %(?a\n<a>\n),
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:uri/text()", "a"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                           ["/table[@class='sparql']/tbody/tr/td/text()", "&lt;a&gt;"],
                         ],
                        },
      :node          => {solution: [{a: RDF::Node.new("a")}],
                         :json     => {
                           head: {vars: ["a"]},
                           results: {bindings: [{"a" => {type: "bnode", value: "a" }}]}
                         },
                         csv: %(a\r\n_:a\r\n),
                         tsv: %(?a\n_:a\n),
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:bnode/text()", "a"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                           ["/table[@class='sparql']/tbody/tr/td/text()", "_:a"],
                         ],
                        },
      literal_plain: {solution: [{a: RDF::Literal("a")}],
                         :json     => {
                           head: {vars: ["a"]},
                           results: {bindings: [{"a" => {type: "literal", value: "a" }}]}
                         },
                         csv: %(a\r\na\r\n),
                         tsv: %(?a\n"a"\n),
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:literal/text()", "a"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                           ["/table[@class='sparql']/tbody/tr/td/text()", '"a"'],
                         ],
                        },
      :literal_lang  => {solution: [{a: RDF::Literal("a", language: :en)}],
                         :json     => {
                           head: {vars: ["a"]},
                           results: {bindings: [{"a" => {type: "literal", "xml:lang" => "en", value: "a" }}]}
                         },
                         csv: %(a\r\na\r\n),
                         tsv: %(?a\n"a"@en\n),
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:literal[@xml:lang='en']/text()", "a"],
                          ],
                          :html     => [
                            ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                            ["/table[@class='sparql']/tbody/tr/td/text()", '"a"@en'],
                          ],
                        },
      :literal_dt    => {solution: [{a: RDF::Literal(1)}],
                         :json     => {
                           head: {vars: ["a"]},
                           results: {bindings: [{"a" => {type: "typed-literal", "datatype" => RDF::XSD.integer.to_s, value: "1" }}]}
                         },
                         csv: %(a\r\n1\r\n),
                         tsv: %(?a\n1\n),
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding/@name", "a"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='a']/sr:literal[@datatype='#{RDF::XSD.integer}']/text()", "1"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th/text()", "a"],
                           ["/table[@class='sparql']/tbody/tr/td/text()", %("1"^^&lt;#{RDF::XSD.integer}&gt;)],
                         ],
                        },
      :literals    => {solution: [{integer: RDF::Literal(1), decimal: RDF::Literal::Decimal.new(1.1), double: RDF::Literal(1.1), token: RDF::Literal(:tok)}],
                         :json     => {
                           head: {vars: %w(integer decimal double token)},
                           results: {bindings: [{
                             "integer" => {type: "typed-literal", "datatype" => RDF::XSD.integer.to_s, value: "1"},
                             "decimal" => {type: "typed-literal", "datatype" => RDF::XSD.decimal.to_s, value: "1.1"},
                             "double" => {type: "typed-literal", "datatype" => RDF::XSD.double.to_s, value: "1.1"},
                             "token" => {type: "typed-literal", "datatype" => RDF::XSD.token.to_s, value: "tok"},
                            }]}
                         },
                         csv: %(integer,decimal,double,token\r\n) +
                                 %(1,1.1,1.1,tok\r\n),
                         tsv: %(?integer\t?decimal\t?double\t?token\n) +
                                 %(1\t1.1\t1.1E0\t"tok"^^<http://www.w3.org/2001/XMLSchema#token>\n),
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='integer']/sr:literal[@datatype='#{RDF::XSD.integer}']/text()", "1"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='decimal']/sr:literal[@datatype='#{RDF::XSD.decimal}']/text()", "1.1"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='double']/sr:literal[@datatype='#{RDF::XSD.double}']/text()", "1.1"],
                           ["/sr:sparql/sr:results/sr:result/sr:binding[@name='token']/sr:literal[@datatype='#{RDF::XSD.token}']/text()", "tok"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr/th[1]/text()", "integer"],
                           ["/table[@class='sparql']/tbody/tr/th[2]/text()", "decimal"],
                           ["/table[@class='sparql']/tbody/tr/th[3]/text()", "double"],
                           ["/table[@class='sparql']/tbody/tr/th[4]/text()", "token"],
                           ["/table[@class='sparql']/tbody/tr/td[1]/text()", %("1"^^&lt;#{RDF::XSD.integer}&gt;)],
                           ["/table[@class='sparql']/tbody/tr/td[2]/text()", %("1.1"^^&lt;#{RDF::XSD.decimal}&gt;)],
                           ["/table[@class='sparql']/tbody/tr/td[3]/text()", %("1.1"^^&lt;#{RDF::XSD.double}&gt;)],
                           ["/table[@class='sparql']/tbody/tr/td[4]/text()", %("tok"^^&lt;#{RDF::XSD.token}&gt;)],
                         ],
                        },
      :missing_var   => {solution: [
                            {entity: RDF::URI("http://localhost/people/1"), middle_name: RDF::Literal("blah")},
                            {entity: RDF::URI("http://localhost/people/2")}
                          ],
                         :json     => {
                           head: {vars: ["entity", "middle_name"]},
                           results: {bindings: [
                             {"entity" => {type: "uri", "value" => "http://localhost/people/1"}, "middle_name" => {type: "literal", value: "blah"}},
                             {"entity" => {type: "uri", "value" => "http://localhost/people/2"}}
                           ]}
                         },
                         csv: %(entity,middle_name\r\n) +
                                 %(http://localhost/people/1,blah\r\n) +
                                 %(http://localhost/people/2,""\r\n),
                         tsv: %(?entity\t?middle_name\n) +
                                 %(<http://localhost/people/1>\t"blah"\n) +
                                 %(<http://localhost/people/2>\t\n),
                         :xml      => [
                           ["/sr:sparql/sr:results/sr:result[1]/sr:binding[@name='entity']/sr:uri/text()", "http://localhost/people/1"],
                           ["/sr:sparql/sr:results/sr:result[1]/sr:binding[@name='middle_name']/sr:literal/text()", "blah"],
                           ["/sr:sparql/sr:results/sr:result[2]/sr:binding[@name='entity']/sr:uri/text()", "http://localhost/people/2"],
                         ],
                         :html     => [
                           ["/table[@class='sparql']/tbody/tr[1]/th[1]/text()", "entity"],
                           ["/table[@class='sparql']/tbody/tr[1]/th[2]/text()", "middle_name"],
                           ["/table[@class='sparql']/tbody/tr[2]/td[1]/text()", %q(&lt;http://localhost/people/1&gt;)],
                           ["/table[@class='sparql']/tbody/tr[2]/td[2]/text()", '"blah"'],
                           ["/table[@class='sparql']/tbody/tr[3]/td[1]/text()", %q(&lt;http://localhost/people/2&gt;)],
                         ],
                        },
      :multiple      => {
                        solution: [
                            {x: RDF::Node.new("a"), y: RDF::Vocab::DC.title, z: RDF::Literal("Hello, world!")},
                            {x: RDF::Node.new("b"), y: RDF::Vocab::DC.title, z: RDF::Literal("Foo bar")},
                          ],
                         json: {
                           head: {vars: ["x", "y", "z"]},
                           results: {
                             bindings: [
                               {
                                 x: {type: "bnode",   value: "a"},
                                 y: {type: "uri",     value: "http://purl.org/dc/terms/title"},
                                 z: {type: "literal", value: "Hello, world!"}
                               },
                               {
                                 x: {type: "bnode",   value: "b"},
                                 y: {type: "uri",     value: "http://purl.org/dc/terms/title"},
                                 z: {type: "literal", value: "Foo bar"}
                               }
                             ]
                           }
                         },
                         csv: %(x,y,z\r\n) +
                                 %(_:a,http://purl.org/dc/terms/title,"Hello, world!"\r\n) +
                                 %(_:b,http://purl.org/dc/terms/title,Foo bar\r\n),
                         tsv: %(?x\t?y\t?z\n) +
                                 %(_:a\t<http://purl.org/dc/terms/title>\t"Hello, world!"\n) +
                                 %(_:b\t<http://purl.org/dc/terms/title>\t"Foo bar"\n),
                         xml: [
                           ["/sr:sparql/sr:results/sr:result[1]/sr:binding[@name='x']/sr:bnode/text()", "a"],
                           ["/sr:sparql/sr:results/sr:result[1]/sr:binding[@name='y']/sr:uri/text()", "http://purl.org/dc/terms/title"],
                           ["/sr:sparql/sr:results/sr:result[1]/sr:binding[@name='z']/sr:literal/text()", "Hello, world!"],
                           ["/sr:sparql/sr:results/sr:result[2]/sr:binding[@name='x']/sr:bnode/text()", "b"],
                           ["/sr:sparql/sr:results/sr:result[2]/sr:binding[@name='y']/sr:uri/text()", "http://purl.org/dc/terms/title"],
                           ["/sr:sparql/sr:results/sr:result[2]/sr:binding[@name='z']/sr:literal/text()", "Foo bar"],
                         ],
                         html: [
                           ["/table[@class='sparql']/tbody/tr[1]/th[1]/text()", "x"],
                           ["/table[@class='sparql']/tbody/tr[1]/th[2]/text()", "y"],
                           ["/table[@class='sparql']/tbody/tr[1]/th[3]/text()", "z"],
                           ["/table[@class='sparql']/tbody/tr[2]/td[1]/text()", "_:a"],
                           ["/table[@class='sparql']/tbody/tr[2]/td[2]/text()", %q(&lt;http://purl.org/dc/terms/title&gt;)],
                           ["/table[@class='sparql']/tbody/tr[2]/td[3]/text()", '"Hello, world!"'],
                           ["/table[@class='sparql']/tbody/tr[3]/td[1]/text()", "_:b"],
                           ["/table[@class='sparql']/tbody/tr[3]/td[2]/text()", %q(&lt;http://purl.org/dc/terms/title&gt;)],
                           ["/table[@class='sparql']/tbody/tr[3]/td[3]/text()", '"Foo bar"'],
                         ]
                        },
    }

    SOLUTIONS.each do |n, r|
      describe "encodes a #{n}" do
        subject {
          RDF::Query::Solutions.new([r[:solution]].flatten.map {|h| RDF::Query::Solution.new(h)})
        }
        its(:to_json) {should == r[:json].to_json}
        its(:to_csv) {should == r[:csv]}
        its(:to_tsv) {should == r[:tsv]}

        describe "to_xml" do
          r[:xml].each do |(xp, value)|
            it "has xpath #{xp} = #{value.inspect}" do
              expect(subject.to_xml).to have_xpath(xp, value)
            end
          end
        end

        describe "to_html" do
          r[:html].each do |(xp, value)|
            it "has xpath #{xp} = #{value.inspect}" do
              expect(subject.to_html).to have_xpath(xp, value)
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
                           :json     => {boolean: true},
                           :xml      => [
                             ["/sr:sparql/sr:boolean/text()", "true"],
                           ],
                           :html     => [
                             ["/div[@class='sparql']/text()", "true"],
                           ],
                          },
        :false         => { :value    => false,
                           :json     => {boolean: false},
                           :xml      => [
                             ["/sr:sparql/sr:boolean/text()", "false"],
                           ],
                           :html     => [
                             ["/div[@class='sparql']/text()", "false"],
                           ],
                          },
        :rdf_true      => { :value    => RDF::Literal::TRUE,
                           :json     => {boolean: true},
                           :xml      => [
                             ["/sr:sparql/sr:boolean/text()", "true"],
                           ],
                           :html     => [
                             ["/div[@class='sparql']/text()", "true"],
                           ],
                          },
        :rdf_false     => { :value    => RDF::Literal::FALSE,
                           :json     => {boolean: false},
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
            subject {SPARQL.serialize_results(r[:value], format: :json)}
            it "uses format: :json" do
              expect(subject).to eq r[:json].to_json
            end

            it "uses using content_types: 'application/sparql-results+json'" do
              s = SPARQL.serialize_results(r[:value], content_types: 'application/sparql-results+json')
              expect(s).to eq subject
            end

            it "returns 'application/sparql-results+json' for #content_type" do
              expect(subject.content_type).to eq 'application/sparql-results+json'
            end

            describe "content negotation" do
              {
                "json" => ["application/sparql-results+json"],
                "json, xml" => ["application/sparql-results+json", "application/sparql-results+xml"],
                "nt, json" => ["text/plain", "application/sparql-results+json"],
              }.each do |title, accepts|
                it "with #{title}" do
                  s = SPARQL.serialize_results(r[:value], content_types: accepts)
                  expect(s).to eq subject
                  expect(s.content_type).to eq 'application/sparql-results+json'
                end
              end
            end
          end
        end
      end
      
      context "xml" do
        BOOLEAN.each do |n, r|
          describe "encoding #{n}" do
            r[:xml].each do |(xp, value)|
              subject {SPARQL.serialize_results(r[:value], format: :xml)}
              it "has xpath #{xp} = #{value.inspect} using format: :xml" do
                expect(subject).to have_xpath(xp, value)
              end

              it "has xpath #{xp} = #{value.inspect} using content_types: 'application/sparql-results+xml'" do
                s = SPARQL.serialize_results(r[:value], content_types: 'application/sparql-results+xml')
                expect(s).to eq subject
              end
              
              it "returns 'application/sparql-results+xml' for #content_type" do
                expect(subject.content_type).to eq 'application/sparql-results+xml'
              end
            end

            describe "content negotation" do
              {
                "xml" => ["application/sparql-results+xml"],
                "xml, json" => ["application/sparql-results+xml", "application/sparql-results+json"],
                "nt, xml" => ["text/plain", "application/sparql-results+xml"],
              }.each do |title, accepts|
                it "with #{title}" do
                  s = SPARQL.serialize_results(r[:value], content_types: accepts)
                  expect(s).to eq subject
                  expect(s.content_type).to eq 'application/sparql-results+xml'
                end
              end
            end
          end
        end
      end
      
      context "html" do
        BOOLEAN.each do |n, r|
          describe "encoding #{n}" do
            r[:html].each do |(xp, value)|
              subject {SPARQL.serialize_results(r[:value], format: :html)}
              it "has xpath #{xp} using format: :html" do
                expect(subject).to have_xpath(xp, value)
              end

              it "has xpath #{xp} using content_types: 'text/html'" do
                s = SPARQL.serialize_results(r[:value], content_types: 'text/html')
                expect(s).to eq subject
              end
              
              it "returns 'text/html' for #content_type" do
                expect(subject.content_type).to eq 'text/html'
              end

              describe "content negotation" do
                {
                  "html" => ["text/html"],
                  "html, xml" => ["text/html", "application/sparql-results+xml"],
                  "nt, html" => ["text/plain", "text/html"],
                }.each do |title, accepts|
                  it "with #{title}" do
                    s = SPARQL.serialize_results(r[:value], content_types: accepts)
                    expect(s).to eq subject
                    expect(s.content_type).to eq 'text/html'
                  end
                end
              end
            end
          end
        end
      end
      
      context "rdf content-types" do
        it "raises error with format :ntriples" do
          expect {SPARQL.serialize_results(true, format: :ntriples)}.to raise_error(RDF::WriterError, /Unknown format :ntriples/)
        end
      end
    end

    context "graph" do
      {
        ntriples: 'application/n-triples',
        :turtle   => 'text/turtle',
      }.each do |format, content_type|
        context "with format #{format}" do
          before(:each) do
            @solutions = double("Solutions")
            @solutions.extend(RDF::Queryable)
            expect(@solutions).to receive(:dump).with(format, anything).at_least(1).and_return("serialized graph")
          end

          subject {SPARQL.serialize_results(@solutions, format: format)}

          it "serializes graph with format #{format.inspect}" do
            expect(subject).to eq "serialized graph"
          end

          it "serializes graph with content_type #{content_type}" do
            s = SPARQL.serialize_results(@solutions, content_types: content_type)
            expect(s).to eq subject
          end
      
          it "returns #{content_type} for #content_type" do
            expect(subject.content_type).to eq content_type
          end
        end
      end
    end
    
    context "solutions" do
      before(:each) do
        @solutions = RDF::Query::Solutions(RDF::Query::Solution.new(a: RDF::Literal("b")))
      end
      
      SPARQL::Results::MIME_TYPES.each do |format, content_type|
        context "with format #{format}" do
          it "serializes results wihth format #{format.inspect}" do
            expect(@solutions).to receive("to_#{format}").and_return("serialized results")
            s = SPARQL.serialize_results(@solutions, format: format)
            expect(s).to eq "serialized results"
            expect(s.content_type).to eq content_type
          end
        end
      end

      context "rdf content-types" do
        it "raises error with format :ntriples" do
          expect {SPARQL.serialize_results(@solutions, format: :ntriples)}.to raise_error(RDF::WriterError)
        end
      end
    end
  end
  
  describe "#serialize_exception" do
    [{format: :html}, {content_type: "text/html"}].each do |options|
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
                expect(subject).to have_xpath(xp, value)
              end
            
              it "has content_type text/html" do
                expect(subject.content_type).to eq 'text/html'
              end
            end
          end
        end
      end
    end

    [{format: :xml}, {content_types: "application/sparql-results+xml"}, {}].each do |options|
      context "with options #{options.inspect}" do
        {
          SPARQL::MalformedQuery      => "Malformed Query",
          SPARQL::QueryRequestRefused => "Query Request Refused",
          RuntimeError                => "RuntimeError"
        }.each do |cls, title|
          context "for #{cls}" do
            subject { SPARQL.serialize_exception(cls.new("error string"), options)}

            it "has simple error string" do
              expect(subject).to eq "error string"
            end

            it "has content_type text/plain" do
              expect(subject.content_type).to eq 'text/plain'
            end
          end
        end
      end
    end
  end
end
