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
        default_datasets = []
        named_datasets = []
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
            named_datasets << uri
          else
            uri = self.base_uri ? self.base_uri.join(ds) : ds
            debug(options) {"=> default data source #{uri}"}
            default_datasets << uri
          end
          load_opts[:context] = load_opts[:base_uri] = uri
          unless queryable.has_context?(uri)
            debug(options) {"=> load #{uri}"}
            queryable.load(uri.to_s, load_opts)
          end
        end
        require 'rdf/nquads'
        debug(options) { queryable.dump(:nquads) }

        # Re-write the operand:
        operator = self.rewrite do |op|
          case op
          when Operator::Graph
            if named_datasets.empty?
              # * If there are no named datasets, remove all (graph)
              #   operations.
              debug(options) {"=> #{op.to_sxp} => (bgp)"}
              Operator::BGP.new
            elsif (name = op.operand(0)).is_a?(RDF::Resource)
              # It must match one of the named_datasets
              debug(options) {"=> #{op.to_sxp} => (bgp)"}
              named_datasets.include?(name) ? op : Operator::BGP.new
            else
              # Name is a variable, replace op with a filter on that
              # variable and op
              filter_expressions = named_datasets.map {|u| Operator::Equal.new(name, u)}
              debug(options) {"=> #{op.to_sxp} => (filter (...) #{op.to_sxp})"}
              filt = to_binary(Operator::Or, *filter_expressions)
              Operator::Filter.new(filt, op)
            end
          when RDF::Query # Operator::BGP
            case default_datasets.length
            when 0
              # No Default Datasets, no query to run
              debug(options) {"=> #{op.to_sxp} => (bgp)"}
              Operator::BGP.new
            when 1
              # A single dataset, write as (graph <dataset> (bgp))
              debug(options) {"=> #{op.to_sxp} => (graph <#{default_datasets.first}> #{op.to_sxp})"}
              Operator::Graph.new(default_datasets.first, op)
            else
              # Several, rewrite as Union
              debug(options) {"=> #{op.to_sxp} => (union ...)"}
              to_binary(Operator::Union, *default_datasets.map {|u| Operator::Graph.new(u, op.dup)})
            end
          else
            nil
          end
        end
        executable = operator.operands.last
        debug(options) {"=> rewritten: #{executable.to_sxp}"}

        @solutions = executable.execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
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
