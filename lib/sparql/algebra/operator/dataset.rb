module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `dataset` operator.
    #
    # Instintiated with two operands, the first being an array of data source URIs,
    # either bare, indicating a default dataset, or expressed as an array [:named, <uri>],
    # indicating that it represents a named data source.
    #
    # @example
    #   (prefix ((: <http://example/>))
    #     (dataset (<data-g1.ttl> (named <data-g2.ttl>))
    #       (bgp (triple ?s ?p ?o))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#specifyingDataset
    class Dataset < Binary
      include Query
      
      NAME = [:dataset]

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
        operand(0).each do |ds|
          load_opts = {}
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
            load_opts[:context] = uri
            debug(options) {"=> read named data source #{uri}"}
          else
            debug(options) {"=> array: join #{self.base_uri.inspect} to #{ds.inspect}"}
            uri = self.base_uri ? self.base_uri.join(ds) : ds
            debug(options) {"=> read default data source #{uri}"}
          end
          load_opts[:base_uri] = uri
          load_opts[:headers] = {
            "Accept" => 'text/turtle, application/rdf+xml;q=0.8, text/plain;q=0.4, */*;q=0.1'
          }
          queryable.load(uri.to_s, load_opts)
        end

        @solutions = operands.last.execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
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
