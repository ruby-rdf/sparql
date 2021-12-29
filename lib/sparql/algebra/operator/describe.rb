module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `describe` operator.
    #
    # Generages a graph across specified terms using {RDF::Queryable}`#concise_bounded_description`.
    #
    # [11]  DescribeQuery           ::= 'DESCRIBE' ( VarOrIri+ | '*' ) DatasetClause* WhereClause? SolutionModifier ValuesClause
    #
    # @example SPARQL Grammar
    #   BASE <http://example.org/>
    #   DESCRIBE <u> ?u WHERE { <x> <q> ?u . }
    #
    # @example SSE
    #   (base <http://example.org/>
    #    (describe (<u> ?u)
    #     (bgp (triple <x> <q> ?u))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#describe
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
      # @yield  [statement]
      #   each matching statement
      # @yieldparam  [RDF::Statement] solution
      # @yieldreturn [void] ignored
      # @return [RDF::Graph]
      #   containing the constructed triples
      # @see    https://www.w3.org/TR/sparql11-query/#describe
      def execute(queryable, **options, &block)
        debug(options) {"Describe #{operands.first}, #{options.inspect}"}

        # Describe any constand URIs
        to_describe = operands.first.select {|t| t.uri?}
        
        to_describe.each {|t| debug(options) {"=> describe #{t}"}}

        queryable.query(operands.last) do |solution|
          solution.each_variable do |v|
            if operands.first.any? {|bound| v.eql?(bound)}
              debug(options) {"(describe)=> #{v}"}
              to_describe << v.value
            end
          end
        end

        # Return Concise Bounded Description
        queryable.concise_bounded_description(*to_describe.uniq, &block)
      end

      # Query results statements (e.g., CONSTRUCT, DESCRIBE, CREATE)
      # @return [Boolean]
      def query_yields_statements?
        true
      end

      ##
      #
      # Returns a partial SPARQL grammar for this term.
      #
      # @return [String]
      def to_sparql(**options)
        str = "DESCRIBE "
        str << if operands[0].empty?
          "*"
        else
          operands[0].map { |e| e.to_sparql(**options) }.join(" ")
        end

        str << "\n"
        str << operands[1].to_sparql(top_level: true, project: nil, **options)
      end
    end # Construct
  end # Operator
end; end # SPARQL::Algebra
