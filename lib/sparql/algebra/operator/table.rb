module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Table operator.
    #
    # This is used to provide inline values. Each row becomes
    # a solution.
    #
    # @example
    #    (table (vars ?book ?title)
    #      (row (?title "SPARQL Tutorial"))
    #      (row (?book :book2)))
    #
    # @see http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#inline-data
    class Table < Operator
      include Query
      
      NAME = [:table]

      ##
      # Returns solutions for each row
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
      def execute(queryable, options = {}, &block)
        @solutions = RDF::Query::Solutions()
        operands[1..-1].each do |row|
          next unless row.is_a?(Array)
          bindings = row[1..-1].inject({}) do |memo, (var, value)|
            memo[var.to_sym] = value unless value == :undef
            memo
          end
          @solutions << RDF::Query::Solution.new(bindings)
        end
        @solutions.each(&block) if block_given?
        @solutions
      end
    end # Table
  end # Operator
end; end # SPARQL::Algebra
