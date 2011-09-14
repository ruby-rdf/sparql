$:.unshift "."
require 'spec_helper'
require 'dawg_helper'
require 'rdf/rdfxml'

describe SPARQL::Grammar do
  describe "w3c dawg SPARQL evaluation tests" do
    SPARQL::Spec.sparql1_0_tests.group_by(&:manifest).each do |man, tests|
      describe man.to_s.split("/")[-2] do
        tests.each do |t|
          case t.type
          when MF.QueryEvaluationTest
            it "evaluates #{t.name}" do

              graphs = t.graphs
              query = t.action.query_string
              expected = t.solutions

              result = sparql_query(:graphs => graphs, :query => query, :base_uri => t.action.query_file,
                                    :repository => "sparql-spec", :form => t.form, :to_hash => false)

              case t.name
              when /Cast to xsd:boolean/
                pending("figuring out why xsd:boolean doesn't behave according to http://www.w3.org/TR/rdf-sparql-query/#FunctionMapping")
              when /normalization-02/
                pending("Addressable normalizes when joining URIs")
              when /REDUCED/
                pending("REDUCED equivalent to DISTINCT")
              end
              
              case t.form
              when :select
                result.should be_a(RDF::Query::Solutions)
                if man.to_s =~ /sort/
                  result.should describe_ordered_solutions(expected)
                else
                  result.should describe_solutions(expected)
                end
              when :create, :describe
                result.should be_a(RDF::Queryable)
                result.should describe_solutions(expected)
              when :ask
                result.should be_true
              end
            end
          else
            it "??? #{t.name}" do
              puts t.inspect
              fail "Unknown test type #{t.type}"
            end
          end
        end
      end
    end
  end
end