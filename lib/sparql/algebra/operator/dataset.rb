begin
  require 'linkeddata'
rescue LoadError => e
  require 'rdf/ntriples'
end

# FIXME: This version uses named graphs for default graphs, which violates the condition in RDF::Repository#query_pattern, where it specifically does not match variables against the default graph. To work properly, RDF.rb will need to allow some way to specify a set of graphs as being default, and affect the matching within #query_pattern so that variables don't match against this.
# Note that a graph may be both default and named, so the context of the query is significant.
module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `dataset` operator.
    #
    # Instantiated with two operands, the first being an array of data source URIs,
    # either bare, indicating a default dataset, or expressed as an array `\[:named, \<uri\>\]`,
    # indicating that it represents a named data source.
    #
    # This operator loads the document referenced by the URI into the dataset
    # using `uri` as the graph name, unless it already exists within the dataset.
    #
    # The contained BGP queries are then performed against the specified
    # default and named graphs. Rather than using the actual default
    # graph of the dataset, queries against the default dataset are
    # run against named graphs matching a non-distinctive variable
    # and the results are filtered against those URIs included in
    # the default dataset.
    #
    # @example
    #
    #     (prefix ((: <http://example/>))
    #       (dataset (<data-g1.ttl> (named <data-g2.ttl>))
    #         (union
    #           (bgp (triple ?s ?p ?o))
    #           (graph ?g (bgp (triple ?s ?p ?o))))))
    #
    # is effectively re-written to the following:
    #
    #     (prefix ((: <http://example/>))
    #       (dataset (<data-g1.ttl> (named <data-g2.ttl>))
    #         (filter (= ??g <data-g1.ttl>)
    #           (union
    #             (graph ??g (bgp (triple ?s ?p ?o)))
    #             (graph ?g (bgp (triple ?s ?p ?o)))))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#specifyingDataset
    class Dataset < Binary
      include Query

      NAME = [:dataset]
      # Selected accept headers, from those available
      ACCEPTS = (%w(
        text/turtle
        application/rdf+xml;q=0.8
        application/n-triples;q=0.4
        text/plain;q=0.1
      ).
        select do |content_type|
          # Add other content types
          RDF::Format.content_types.include?(content_type.split(';').first)
        end << ' */*;q=0.2').join(', ').freeze

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Reads specified data sources into queryable. Named data sources
      # are added using a _context_ of the data source URI.
      #
      # Datasets are specified in operand(1), which is an array of default or named graph URIs.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      def execute(queryable, options = {})
        debug(options) {"Dataset"}
        default_graphs = []
        operand(0).each do |ds|
          load_opts = {
            :headers => {"Accept" => ACCEPTS}
          }
          load_opts[:debug] = options.fetch(:debug, nil)
          case ds
          when Array
            # Format is (named <uri>), only need the URI part
            uri = if self.base_uri
              u = self.base_uri.join(ds.last)
              u.lexical = "<#{ds.last}>" unless u.to_s == ds.last.to_s
              u
            else
              ds.last
            end
            uri = self.base_uri ? self.base_uri.join(ds.last) : ds.last
            uri.lexical = ds.last
            debug(options) {"=> named data source #{uri}"}
          else
            debug(options) {"=> array: join #{self.base_uri.inspect} to #{ds.inspect}"}
            uri = self.base_uri ? self.base_uri.join(ds) : ds
            debug(options) {"=> default data source #{uri}"}
            default_graphs << uri
          end
          load_opts[:context] = load_opts[:base_uri] = uri
          unless queryable.has_context?(uri)
            debug(options) {"=> load #{uri}"}
            queryable.load(uri.to_s, load_opts)
          end
        end

        # Query binding a non-distinguishded variable to context
        default_var = RDF::Query::Variable.new
        default_var.distinguished = false

        @solutions = operands.last.execute(queryable, options.merge(
          :context => default_var,
          :depth => options[:depth].to_i + 1)
        ).filter do |soln|
          # Reject solutions with bindings to default_var where the value
          # is not a specified default graph
          debug(options) {"=> filter: #{soln.inspect}"}
          if soln.unbound?(default_var)
            true
          elsif default_graphs.include?(soln[default_var])
            # Remove the variable from the solution and match
            # FIXME: this should either go in RDF::Query::Solution,
            # or there should be a immutable way of performing this
            # as an operation on RDF::Query::Solutions
            soln.bindings.delete(default_var.to_sym)
          end
        end
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # If optimize operands, and if the first two operands are both Queries, replace
      # with the unique sum of the query elements
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        operands.last.optimize
      end
    end # Dataset
  end # Operator
end; end # SPARQL::Algebra
