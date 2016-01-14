module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `construct` operator.
    #
    # The CONSTRUCT query form returns a single RDF graph specified by a graph template. The result is an RDF graph formed by taking each query solution in the solution sequence, substituting for the variables in the graph template, and combining the triples into a single RDF graph by set union.
    #
    # @example
    #   (prefix ((rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
    #            (foaf: <http://xmlns.com/foaf/0.1/>))
    #     (construct ((triple ?s ?p ?o))
    #       (project (?s ?p ?o)
    #         (bgp (triple ?s ?p ?o)))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#construct
    class Construct < Operator::Binary
      include Query
      
      NAME = [:construct]

      ##
      # Executes this query on the given {RDF::Queryable} object.
      # Binds variables to the array of patterns in the first operand and returns the resulting RDF::Graph object
      #
      # If any such instantiation produces a triple containing an unbound variable or an illegal RDF construct, such as a literal in subject or predicate position, then that triple is not included in the output RDF graph. The graph template can contain triples with no variables (known as ground or explicit triples), and these also appear in the output RDF graph returned by the CONSTRUCT query form.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @yield  [statement]
      #   each matching statement
      # @yieldparam  [RDF::Statement] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Queryable]
      #   A Queryable with constructed triples
      # @see    http://www.w3.org/TR/sparql11-query/#construct
      def execute(queryable, options = {}, &block)
        debug(options) {"Construct #{operands.first}, #{options.inspect}"}
        graph = RDF::Graph.new
        patterns = operands.first
        query = operands.last

        queryable.query(query, options.merge(depth: options[:depth].to_i + 1)).each do |solution|
          debug(options) {"(construct apply) #{solution.inspect} to BGP"}
          
          # Create a mapping from BNodes within the pattern list to newly constructed BNodes
          nodes = {}
          patterns.each do |pattern|
            terms = {}
            [:subject, :predicate, :object].each do |r|
              terms[r] = case o = pattern.send(r)
              when RDF::Node            then nodes[o] ||= RDF::Node.new
              when RDF::Query::Variable then solution[o]
              else                           o
              end
            end
            
            statement = RDF::Statement.from(terms)

            # Sanity checking on statement
            if statement.subject.nil? || statement.predicate.nil? || statement.object.nil? ||
               statement.subject.literal? || statement.predicate.literal?
              debug(options) {"(construct skip) #{statement.inspect}"}
              next
            end

            debug(options) {"(construct add) #{statement.inspect}"}
            graph << statement
          end
        end

        debug(options) {"=>\n#{graph.dump(:ttl, standard_prefixes: true)}"}
        graph.each(&block) if block_given?
        graph
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Return optimized query
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        operands = operands.map(&:optimize)
      end

      # Query results statements (e.g., CONSTRUCT, DESCRIBE, CREATE)
      # @return [Boolean]
      def query_yields_statements?
        true
      end
    end # Construct
  end # Operator
end; end # SPARQL::Algebra
