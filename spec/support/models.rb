require 'rdf'
require 'spira'
require 'rdf/turtle'
require 'sparql/client'

module SPARQL; module Spec
  DAWGT = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-dawg#')
  ENT   = RDF::Vocabulary.new('http://www.w3.org/ns/entailment/RDF')
  MF    = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-manifest#')
  QT    = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/test-query#')
  RS    = RDF::Vocabulary.new('http://www.w3.org/2001/sw/DataAccess/tests/result-set#')
  UT    = RDF::Vocabulary.new('http://www.w3.org/2009/sparql/tests/test-update#')

  class Manifest < Spira::Base
    type MF.Manifest
    has_many :manifests,  :predicate => MF.include
    property :entry_list, :predicate => MF.entries
    property :comment,    :predicate => RDFS.comment

    def entries
      RDF::List.new(entry_list, self.class.repository).map do |entry|
        type = self.class.repository.first_object(:subject => entry, :predicate => RDF.type)
        case type
          when UT.UpdateEvaluationTest, MF.UpdateEvaluationTest
            entry.as(UpdateTest)
          when MF.QueryEvaluationTest
            entry.as(QueryTest)
          when MF.CSVResultFormatTest
            entry.as(CSVTest)
          # known types to ignore
          when MF.PositiveSyntaxTest, MF.PositiveSyntaxTest11, MF.PositiveUpdateSyntaxTest11,
               MF.NegativeSyntaxTest, MF.NegativeSyntaxTest11, MF.NegativeUpdateSyntaxTest11
            entry.as(SyntaxTest)
          when MF.ServiceDescriptionTest, MF.ProtocolTest,
               MF.GraphStoreProtocolTest
            # Ignore
          else
            warn "Unknown test type for #{entry}: #{type}"
        end
      end.compact
    end

    def include_files!
      manifests.each do |manifest|
        RDF::List.new(manifest, self.class.repository).each do |file|
          puts "Loading #{file}"
          self.class.repository.load(file, :context => file, :base_uri => file)
        end
      end
    end
  end

  class Spira::Base
    def encode_with(coder)
      coder["subject"] = subject
      attributes.each {|p,v| coder[p.to_s] = v if v}
    end

    def init_with(coder)
      self.instance_variable_set(:"@subject", coder["subject"])
      self.reload
      attributes.each {|p,v| self.attribute_set(p, coder.map[p.to_s])}
    end

    def inspect
      "<#{self.class}:#{self.object_id} @subject: #{@subject}>[" + attributes.keys.map do |a|
        v = attributes[a]; "#{a}=#{v.inspect}" if v
      end.compact.join("\n  ") +
      "]"
    end
  end
  
  class SPARQLTest < Spira::Base
    property :name, :predicate => MF.name
    property :type, :predicate => RDF.type
    property :comment, :predicate => RDFS.comment
    property :approval, :predicate => DAWGT.approval
    property :approved_by, :predicate => DAWGT.approvedBy
    property :manifest, :predicate => MF.manifest_file
    has_many :tags, :predicate => MF.tag

    def approved?
      approval == DAWGT.Approved
    end

    def entry; "??"; end

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
    property :result, :predicate => MF.result, :type => 'UpdateResult'
    property :action, :predicate => MF.action, :type => 'UpdateAction'

    def query_file
      action.request
    end

    def entry; query_file.to_s.split('/').last; end

    def template_file
      'update-test.rb.erb'
    end

    def query
      RDF::Util::File.open_file(query_file, &:read)
    end
  end

  class UpdateDataSet < Spira::Base
    has_many :graphData, :predicate => UT.graphData, :type => 'UpdateGraphData'
    property :data_file, :predicate => UT.data

    def data
      RDF::Util::File.open_file(data_file, &:read)
    end

    def data_format
      File.extname(data_file).sub(/\./,'').to_sym
    end
  end

  class UpdateAction < UpdateDataSet
    property :request, :predicate => UT.request

    def query_file
      request
    end

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
  end

  class UpdateResult < UpdateDataSet
  end

  class UpdateGraphData < Spira::Base
    property :graph, :predicate => UT.graph
    property :basename, :predicate => RDFS.label, :type => Spira::Types::URI

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
    property :action, :predicate => MF.action, :type => 'QueryAction'
    property :result, :predicate => MF.result

    def query_file
      action.query_file
    end

    def entry; query_file.to_s.split('/').last; end

    def template_file
      'query-test.rb.erb'
    end

    # Load and return default and named graphs in a hash
    def graphs
      @graphs ||= begin
        graphs = {}
        graphs[:default] = {:data => action.test_data_string, :format => RDF::Format.for(action.test_data.to_s).to_sym} if action.test_data
        action.graphData.each do |g|
          data = RDF::Util::File.open_file(g, &:read)
          graphs[g] = {
            :data => data,
            :format => RDF::Format.for(g.to_s).to_sym,
            :base_uri => g
          }
        end
        graphs
      end
    end

    # Turn results into solutions
    def solutions
      result = self.result if self.respond_to?(:result)
      return nil unless result

      # Use alternate results for RDF 1.1
      if RDF::VERSION.to_s >= "1.1"
        file_11 = result.to_s.
          sub(BASE_URI_10, BASE_DIRECTORY).
          sub(BASE_URI_11, BASE_DIRECTORY).
          sub(/\.(\w+)$/, '_11.\1')
        result = RDF::URI(file_11) if File.exist?(file_11)
      end

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
            expected_repository = RDF::Repository.new 
            Spira.add_repository!(:results, expected_repository)
            expected_repository.load(result)
            SPARQL::Spec::ResultBindings.each.first.solutions
          else
            RDF::Graph.load(result).objects.detect {|o| o.literal?}
          end
        end
      when :describe, :create, :construct
        RDF::Repository.load(result, :base_uri => result, :format => :ttl)
      end
    end

  end

  class CSVTest < QueryTest
  end

  class UpdateTest < SPARQLTest
    property :result, :predicate => MF.result, :type => 'UpdateResult'
    property :action, :predicate => MF.action, :type => 'UpdateAction'

    def query_file
      action.request
    end

    def entry; query_file.to_s.split('/').last; end

    def template_file
      'update-test.rb.erb'
    end

    def query
      RDF::Util::File.open_file(query_file, &:read)
    end
  end

  class SyntaxTest < SPARQLTest
    property :_action, :predicate => MF.action

    # Construct an action instance, as this form only uses a simple URI
    def action
      @action ||= QueryAction.new {|a| a.query_file = _action; a.graphData = []; }
    end

    def entry; _action.to_s.to_s.split('/').last; end

  end

  class QueryAction < Spira::Base
    property :query_file, :predicate => QT.query
    property :test_data,  :predicate => QT.data
    has_many :graphData,  :predicate => QT.graphData

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

  class SPARQLBinding < Spira::Base
    property :value,    :predicate => RS.value, :type => Native
    property :variable, :predicate => RS.variable
    default_source :results
  end

  class BindingSet < Spira::Base
    default_source :results
    has_many :bindings, :predicate => RS.binding, :type => 'SPARQLBinding'
    property :index,    :predicate => RS.index, :type => Integer
  end

  class ResultBindings < Spira::Base
    type RS.ResultSet
    has_many :variables, :predicate => RS.ResultSet
    has_many :solution_lists, :predicate => RS.solution, :type => 'BindingSet'
    property :boolean, :predicate => RS.boolean, :type => Boolean # for ask queries
    default_source :results

    # Return bindings as an list of Solutions
    # @return [Enumerable<RDF::Query::Solution>]
    def solutions
      @solutions ||= begin
        solution_lists.
          sort_by {|solution_list| solution_list.index.to_i}.
          map do |solution_list|
          bindings = solution_list.bindings.inject({}) { |hash, binding|
            hash[binding.variable.to_sym] = binding.value
            hash
          }
          RDF::Query::Solution.new(bindings)
        end
      end
    end

    def self.for_solutions(solutions, opts = {})
      opts[:uri] ||= RDF::Node.new
      index = 1 if opts[:index]
      result_bindings = self.for(opts[:uri]) do | binding_graph |
        solutions.each do | result_hash | 
          binding_graph.solution_lists << BindingSet.new do | binding_set |
            result_hash.to_hash.each_pair do |hash_variable, hash_value|
              binding_set.bindings << SPARQLBinding.new do | sparql_binding |
                sparql_binding.variable = hash_variable.to_s
                sparql_binding.value = hash_value.respond_to?(:canonicalize) ? hash_value.dup.canonicalize : hash_value
              end
            end
            if opts[:index]
              binding_set.index = index
              index += 1
            end
          end
        end
      end
    end

    def self.pretty_print
      self.each do |result_binding|
      log "Result Bindings #{result_binding.subject}"
        result_binding.solution_lists.each.sort { |bs, other| bs.index.respond_to?(:'<=>') ? bs.index <=>  other.index : 0 }.each do |binding_set|
           log "  Solution #{binding_set.subject} (# #{binding_set.index})"
           binding_set.bindings.sort { |b, other| b.variable.to_s <=> other.variable.to_s }.each do |binding|
             log "    #{binding.variable}: #{binding.value.inspect}"
           end
        end
      end
    end

  end
end; end

# Save short version of URI, without all the other stuff.
class RDF::URI
  def encode_with(coder)
    coder["uri"] = self.to_s
  end
  
  def init_with(coder)
    self.instance_variable_set(:@value, coder["uri"])
    self.instance_variable_set(:@object, nil)
  end
end
