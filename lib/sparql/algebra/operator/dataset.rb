begin
  require 'linkeddata'
rescue LoadError => e
  require 'rdf/ntriples'
end
require 'rdf/aggregate_repo'

module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `dataset` operator.
    #
    # Instantiated with two operands, the first being an array of data source URIs,
    # either bare, indicating a default dataset, or expressed as an array `\[:named, \<uri\>\]`,
    # indicating that it represents a named data source.
    #
    # This operator loads from the datasource, unless a graph named by
    # the datasource URI already exists in the repository.
    #
    # The contained BGP queries are then performed against the specified
    # default and named graphs. Rather than using the actual default
    # graph of the dataset, queries against the default dataset are
    # run against named graphs matching a non-distinctive variable
    # and the results are filtered against those URIs included in
    # the default dataset.
    #
    # Specifically, each BGP which is not part of a graph pattern
    # is replaced with a union of graph patterns with that BGP repeated
    # for each graph URI in the default dataset. This requires recursively
    # updating the operator.
    #
    # Each graph pattern containing a variable graph name is replaced
    # by a filter on that variable such that the variable must match
    # only those named datasets specified.
    #
    # @example Dataset with one default and one named data source
    #
    #     (prefix ((: <http://example/>))
    #       (dataset (<data-g1.ttl> (named <data-g2.ttl>))
    #         (union
    #           (bgp (triple ?s ?p ?o))
    #           (graph ?g (bgp (triple ?s ?p ?o))))))
    #
    #     is effectively re-written to the following:
    #
    #     (prefix ((: <http://example/>))
    #       (union
    #         (graph <data-g1.ttl> (bgp (triple ?s ?p ?o)))
    #         (filter (= ?g <data-g2.ttl>)
    #           (graph ?g (bgp (triple ?s ?p ?o))))))
    #
    # If no default or no named graphs are specified, these queries
    # are eliminated.
    #
    # @example Dataset with one default no named data sources
    #
    #     (prefix ((: <http://example/>))
    #       (dataset (<data-g1.ttl>)
    #         (union
    #           (bgp (triple ?s ?p ?o))
    #           (graph ?g (bgp (triple ?s ?p ?o))))))
    #
    #     is effectively re-written to the following:
    #
    #     (prefix ((: <http://example/>))
    #       (union
    #         (graph <data-g1.ttl> (bgp (triple ?s ?p ?o)))
    #         (bgp))
    #
    # Multiple default graphs union the information from a graph query
    # on each default datasource.
    #
    # @example Dataset with two default data sources
    #
    #     (prefix ((: <http://example/>))
    #       (dataset (<data-g1.ttl> <data-g1.ttl)
    #         (bgp (triple ?s ?p ?o))))
    #
    #     is effectively re-written to the following:
    #
    #     (prefix ((: <http://example/>))
    #       (union
    #         (graph <data-g1.ttl> (bgp (triple ?s ?p ?o)))
    #         (graph <data-g2.ttl> (bgp (triple ?s ?p ?o)))))
    #
    # Multiple named graphs place a filter on all variables used
    # to identify those named graphs so that they are restricted
    # to come only from the specified set. Note that this requires
    # descending through expressions to find graph patterns using
    # variables and placing a filter on each identified variable.
    #
    # @example Dataset with two named data sources
    #
    #     (prefix ((: <http://example/>))
    #       (dataset ((named <data-g1.ttl>) (named <data-g2.ttl>))
    #         (graph ?g (bgp (triple ?s ?p ?o)))))
    #
    #     is effectively re-written to the following:
    #
    #     (prefix ((: <http://example/>))
    #       (filter ((= ?g <data-g1.ttl>) || (= ?g <data-g2.ttl>))
    #         (graph ?g (bgp (triple ?s ?p ?o))))))
    #
    # @example Dataset with multiple named graphs
    # @see http://www.w3.org/TR/sparql11-query/#specifyingDataset
    class Dataset < Binary
      include Query

      NAME = :dataset

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
      # @yield  [solution]
      #   each matching solution
      # @yieldparam  [RDF::Query::Solution] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, options = {}, &base)
        debug(options) {"Dataset"}
        default_datasets = []
        named_datasets = []
        operand(0).each do |uri|
          case uri
          when Array
            # Format is (named <uri>), only need the URI part
            uri = uri.last
            debug(options) {"=> named data source #{uri}"}
            named_datasets << uri
          else
            debug(options) {"=> default data source #{uri}"}
            default_datasets << uri
          end
          load_opts = {debug: options.fetch(:debug, nil), graph_name: uri, base_uri: uri}
          unless queryable.has_graph?(uri)
            debug(options) {"=> load #{uri}"}
            queryable.load(uri.to_s, load_opts)
          end
        end
        debug(options) {
          require 'rdf/nquads'
          queryable.dump(:nquads)
        }

        # Create an aggregate based on queryable having just the bits we want
        aggregate = RDF::AggregateRepo.new(queryable)
        named_datasets.each {|name| aggregate.named(name) if queryable.has_graph?(name)}
        aggregate.default(*default_datasets.select {|name| queryable.has_graph?(name)})
        aggregate.query(operands.last, options.merge(depth: options[:depth].to_i + 1), &base)
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
