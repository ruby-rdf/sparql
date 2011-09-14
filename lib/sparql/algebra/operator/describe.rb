module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `describe` operator.
    #
    # Generages a graph across specified terms using {RDF::Queryable}`#concise_bounded_description`.
    #
    # @example
    #   (prefix ((exOrg: <http://org.example.com/employees#>))
    #     (describe (?x)
    #       (bgp (triple ?x exOrg:employeeId "1234"))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#describe
    class Describe < Operator::Binary
      include Query
      
      NAME = [:describe]

      ##
      # Executes this query on the given {RDF::Queryable} object.
      # Generates a graph containing the Concise Bounded Description
      # variables and URIs listed in the first operand.
      #
      # @example
      #   (describe (<http://example/>))
      #
      # @example
      #   (prefix ((foaf: <http://xmlns.com/foaf/0.1/>))
      #     (describe (?x)
      #       (bgp (triple ?x foaf:mbox <mailto:alice@org>))))
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#describe
      def execute(queryable, options = {})
        debug("Describe #{operands.first}, #{options.inspect}", options)

        # Describe any constand URIs
        to_describe = operands.first.select {|t| t.uri?}
        
        to_describe.each {|t| debug("=> describe #{t}", options)}

        operands.last.execute(queryable).each do |solution|
          solution.each_variable do |v|
            if operands.first.any? {|bound| v.eql?(bound)}
              debug("=> describe #{v}", options)
              to_describe << v.value
            end
          end
        end

        # Return Concise Bounded Description
        queryable.concise_bounded_description(*to_describe)
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
    end # Construct
  end # Operator
end; end # SPARQL::Algebra
