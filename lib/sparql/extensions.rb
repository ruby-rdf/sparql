require 'rdf'
require 'sparql/results'

##
# Extensions for `RDF::Queryable`
module RDF::Queryable
  ##
  # Concise Bounded Description
  #
  # Given a particular node (the starting node) in a particular RDF graph (the source graph), a subgraph of
  # that particular graph, taken to comprise a concise bounded description of the resource denoted by the
  # starting node, can be identified as follows:
  #
  #   1. Include in the subgraph all statements in the source graph where the subject of the statement is the
  #      starting node;
  #   2. Recursively, for all statements identified in the subgraph thus far having a blank node object,
  #      include in the subgraph all statements in the source graph where the subject of the statement is the
  #      blank node in question and which are not already included in the subgraph.
  #   3. Recursively, for all statements included in the subgraph thus far, for all reifications of each
  #      statement in the source graph, include the concise bounded description beginning from the
  #      rdf:Statement node of each reification. (we skip this step)
  #
  # This results in a subgraph where the object nodes are either URI references, literals, or blank nodes not
  # serving as the subject of any statement in the graph.
  #
  # Used to implement the SPARQL `DESCRIBE` operator.
  #
  # @overload concise_bounded_description(*terms, &block)
  #   @param [Array<RDF::Term>] terms
  #     List of terms to include in the results.
  #
  # @overload concise_bounded_description(*terms, options, &block)
  #   @param [Array<RDF::Term>] terms
  #     List of terms to include in the results.
  #   @param [Hash{Symbol => Object}] options
  #   @option options [Boolean] :non_subjects (false)
  #     If `term` is not a `subject` within `self`
  #     then add all `subject`s referencing the term as a `predicate` or `object`.
  #   @option options [RDF::Graph] graph
  #     Graph containing statements already considered.
  # @yield [statement]
  # @yieldparam [RDF::Statement] statement
  # @yieldreturn [void] ignored
  # @return [RDF::Graph]
  #
  # @see http://www.w3.org/Submission/CBD/
  def concise_bounded_description(*terms, &block)
    options = terms.last.is_a?(Hash) ? terms.pop.dup : {}

    graph = options[:graph] || RDF::Graph.new

    if options[:non_subjects]
      query_terms = terms.dup

      # Find terms not in self as a subject and recurse with their subjects
      terms.reject {|term| self.first(subject: term)}.each do |term|
        self.query(predicate: term) do |statement|
          query_terms << statement.subject
        end

        self.query(object: term) do |statement|
          query_terms << statement.subject
        end
      end
      
      terms = query_terms.uniq
    end

    # Don't consider term if already in graph
    terms.reject {|term| graph.first(subject: term)}.each do |term|
      # Find statements from queryiable with term as a subject
      self.query(subject: term) do |statement|
        yield(statement) if block_given?
        graph << statement
        
        # Include reifications of this statement
        RDF::Query.new({
          s: {
            RDF.type => RDF["Statement"],
            RDF.subject => statement.subject,
            RDF.predicate => statement.predicate,
            RDF.object => statement.object,
          }
        }).execute(self).each do |solution|
          # Recurse to include this subject
          recurse_opts = options.merge(non_subjects: false, graph: graph)
          self.concise_bounded_description(solution[:s], recurse_opts, &block)
        end

        # Recurse if object is a BNode and it is not already in subjects
        if statement.object.node?
          recurse_opts = options.merge(non_subjects: false, graph: graph)
          self.concise_bounded_description(statement.object, recurse_opts, &block)
        end
      end
    end
    
    graph
  end
end

##
# Extensions for `RDF::Query::Solutions`.
class RDF::Query::Solutions
  include SPARQL::Results
end