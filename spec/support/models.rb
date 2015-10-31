require 'rdf'
require 'json/ld'
require 'sparql/client'

module SPARQL; module Spec
  class Manifest < JSON::LD::Resource
    def self.open(file)
      #puts "open: #{file}"
      RDF::Util::File.open_file(file) do |f|
        hash = ::JSON.load(f.read)
        Manifest.new(hash['@graph'].first, graph_name: hash['@context'])
      end
    end

    def include
      # Map entries to resources
      Array(attributes['include']).map {|e| Manifest.open(e.sub(".ttl", ".jsonld"))}
    end

    def entries
      # Map entries to resources
      Array(attributes['entries']).map do |e|
        case e['type']
        when "mf:QueryEvaluationTest", "mf:CSVResultFormatTest"
          QueryTest.new(e)
        when "mf:UpdateEvaluationTest", "ut:UpdateEvaluationTest"
          UpdateTest.new(e)
        when "mf:PositiveSyntaxTest", "mf:NegativeSyntaxTest",
             "mf:PositiveSyntaxTest11", "mf:NegativeSyntaxTest11",
             "mf:PositiveUpdateSyntaxTest11", "mf:NegativeUpdateSyntaxTest11"
          SyntaxTest.new(e)
        else
          SPARQLTest.new(e)
        end
      end
    end
  end

  class SPARQLTest < JSON::LD::Resource
    attr_accessor :debug
    attr_accessor :action

    def query_file
      action.query_file
    end

    def base_uri
      RDF::URI(query_file)
    end

    def entry
      action ? query_file.to_s.split('/').last : '??'
    end


    def approved?
      approval.to_s.include? "Approved"
    end

    def form
      query_data = begin action.query_string rescue nil end
      if query_data =~ /(ASK|CONSTRUCT|DESCRIBE|SELECT|ADD|MOVE|CLEAR|COPY|CREATE|DELETE|DROP|INSERT|LOAD)/i
        case $1.upcase
          when 'ASK', 'SELECT', 'DESCRIBE', 'CONSTRUCT'
            $1.downcase.to_sym
          when 'DELETE', 'LOAD', 'INSERT', 'CREATE', 'CLEAR', 'DROP', 'ADD', 'MOVE', 'COPY'
            :update
        end
      else
        raise "Couldn't determine query type for #{File.basename(subject)} (reading #{action.query_file})"
      end
    end
  end

  class UpdateTest < SPARQLTest
    attr_accessor :result
    def initialize(hash)
      @action = UpdateAction.new(hash["action"])
      @result = UpdateResult.new(hash["result"])
      super
    end

    def query
      RDF::Util::File.open_file(query_file, &:read)
    end

    # For debug output
    def initial
      RDF::Repository.new do |r|
        action.graphs.each do |info|
          data, format, default = info[:data], info[:format], info[:default]
          if data
            RDF::Reader.for(format).new(data, info).each_statement do |st|
              st.graph_name = RDF::URI(info[:base_uri]) if info[:base_uri]
              r << st
            end
          end
        end
      end
    end
  end

  class UpdateDataSet < JSON::LD::Resource
    attr_accessor :graphData
    def initialize(hash)
      @graphData = (hash["ut:graphData"] || []).map {|e| UpdateGraphData.new(e)}
      super
    end

    def data_file; attributes["ut:data"]; end

    def data
      RDF::Util::File.open_file(data_file, &:read)
    end

    def data_format
      File.extname(data_file).sub(/\./,'').to_sym
    end

    # Load and return default and named graphs in a hash
    def graphs
      @graphs ||= begin
        graphs = []
        graphs << {data: data, format: RDF::Format.for(data_file.to_s).to_sym} if data_file
        graphs + graphData.map do |g|
          {
            data: RDF::Util::File.open_file(g.graph.to_s, &:read),
            format: RDF::Format.for(g.graph.to_s).to_sym,
            base_uri: g.basename
          }
        end
      end
    end

    #def to_hash
    #  {graphData: graphs, data_file: data_file}
    #end
  end

  class UpdateAction < UpdateDataSet
    def request; attributes["ut:request"]; end

    def query_file; request; end

    def query_string
      RDF::Util::File.open_file(query_file, &:read)
    end

    def sse_file
      file = query_file.to_s.
        sub(BASE_URI_11, BASE_DIRECTORY).
        sub(/\.ru$/, ".sse")

      # Use alternate file for RDF 1.1
      if RDF::VERSION.to_s >= "1.1"
        file_11 = file.sub(".sse", "_11.sse")
        file = file_11 if File.exist?(file_11)
      end
      RDF::URI(file)
    end
  
    def sse_string
      IO.read(sse_file.path)
    end

    #def to_hash
    #  super.merge(request: request, sse: sse_string, query: query_string)
    #end
  end

  class UpdateResult < UpdateDataSet
  end

  class UpdateGraphData < JSON::LD::Resource
    def graph; attributes["ut:graph"]; end
    def basename; attributes["rdfs:label"]; end

    def data_file
      graph
    end

    def data
      RDF::Util::File.open_file(graph, &:read)
    end

    def data_format
      File.extname(data_file).sub(/\./,'').to_sym
    end
  end

  class QueryTest < SPARQLTest
    def initialize(hash)
      @action = QueryAction.new(hash["action"]) if hash["action"]
      super
    end

    # Load and return default and named graphs in a hash
    def graphs
      @graphs ||= begin
        graphs = []
        graphs << {data: action.test_data_string, format: RDF::Format.for(action.test_data.to_s.to_s).to_sym} if action.test_data
        graphs + action.graphData.map do |g|
          {
            data: RDF::Util::File.open_file(g, &:read),
            format: RDF::Format.for(g.to_s).to_sym,
            base_uri: g
          }
        end
      end
    end

    # Turn results into solutions
    def solutions
      return nil unless self.result
      result = RDF::URI(self.result)

      # Use alternate results for RDF 1.1
      file_11 = result.to_s.
        sub(BASE_URI_10, BASE_DIRECTORY).
        sub(BASE_URI_11, BASE_DIRECTORY).
        sub(/\.(\w+)$/, '_11.\1')
      result = RDF::URI(file_11) if File.exist?(file_11)

      case form
      when :select, :ask
        case File.extname(result.path)
        when '.srx'
          SPARQL::Client.parse_xml_bindings(RDF::Util::File.open_file(result, &:read))
        when '.srj'
          SPARQL::Client.parse_json_bindings(RDF::Util::File.open_file(result, &:read))
        when '.csv'
          SPARQL::Client.parse_csv_bindings(RDF::Util::File.open_file(result, &:read))
        when '.tsv'
          SPARQL::Client.parse_tsv_bindings(RDF::Util::File.open_file(result, &:read))
        else
          if form == :select
            parse_rdf_bindings(RDF::Graph.load(result))
          else
            RDF::Graph.load(result).objects.detect {|o| o.literal?}
          end
        end
      when :describe, :create, :construct
        RDF::Repository.load(result, base_uri: result, format: :ttl)
      end
    end

    RESULT_FRAME = JSON.parse(%q({
      "@context": {
        "rs": "http://www.w3.org/2001/sw/DataAccess/tests/result-set#",

        "resultVariable": {"@id": "rs:resultVariable", "@container": "@set"},
        "solution": {"@id": "rs:solution", "@container": "@set"},
        "binding": {"@id": "rs:binding", "@container": "@set"},
        "variable": "rs:variable",
        "index": {"@id": "rs:index", "@type": "http://www.w3.org/2001/XMLSchema#integer"}
      },
      "@type": "rs:ResultSet"
    }))

    def parse_rdf_bindings(graph)
      JSON::LD::API.fromRDF(graph) do |expanded|
        JSON::LD::API.frame(expanded, RESULT_FRAME) do |framed|
          nodes = {}
          solution = framed['@graph'].first['solution'] if framed['@graph'].first.has_key?('solution')
          solutions = Array(solution).
          sort_by {|s| s['index'].to_i}.
          map do |soln|
            row = soln['binding'].inject({}) do |cols, hash|
              value = case (v = hash['rs:value'])
              when Hash
                case
                when v.has_key?('@value')
                  lang = v['@language'] if v.has_key?('@language')
                  datatype = v['@type'] if v.has_key?('@type')
                  RDF::Literal(v['@value'], language: lang, datatype: datatype)
                when v.has_key?('@id') && v['@id'].to_s.start_with?("_:")
                  nodes[v['@id'][2..-1]] ||= RDF::Node(v['@id'][2..-1])
                when v.has_key?('@id')
                  RDF::URI(v['@id'])
                else v
                end
              else
                RDF::Literal(v)
              end
              cols.merge(hash['variable'].to_sym => value)
            end
            RDF::Query::Solution.new(row)
          end
          @solutions = RDF::Query::Solutions.new(solutions)
        end
      end
      @solutions
    end
  end

  class SyntaxTest < SPARQLTest
    def initialize(hash)
      @action = case hash["action"]
      when String then QueryAction.new({"mq:query" => hash["action"]})
      when Hash   then QueryAction.new(hash["action"])
      end
      super
    end
  end

  class QueryAction < ::JSON::LD::Resource
    def query_file; attributes["mq:query"]; end
    def test_data; attributes["mq:data"]; end
    def graphData; Array(attributes["mq:graphData"]); end

    def query_string
      RDF::Util::File.open_file(query_file, &:read)
    end

    def sse_file
      file = query_file.to_s.
        sub(BASE_URI_10, BASE_DIRECTORY).
        sub(BASE_URI_11, BASE_DIRECTORY).
        sub(/\.r[qu]$/, ".sse")

      # Use alternate file for RDF 1.1
      if RDF::VERSION.to_s >= "1.1"
        file_11 = file.sub(".sse", "_11.sse")
        file = file_11 if File.exist?(file_11)
      end
      RDF::URI(file)
    end
  
    def sse_string
      IO.read(sse_file.path)
    end

    def test_data_string
      RDF::Util::File.open_file(test_data, &:read)
    end
  end

  class SPARQLBinding #< Spira::Base
    #property :value,    predicate: RS.value, type: Native
    #property :variable, predicate: RS.variable
    #default_source :results
  end

  class BindingSet #< Spira::Base
    #default_source :results
    #has_many :bindings, predicate: RS.binding, type: 'SPARQLBinding'
    #property :index,    predicate: RS.index, type: Integer
  end

  class ResultBindings #< Spira::Base
  #end

  end
end; end
