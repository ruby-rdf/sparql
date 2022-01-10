module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL Table operator.
    #
    # This is used to provide inline values. Each row becomes
    # a solution.
    #
    # [28]  ValuesClause            ::= ( 'VALUES' DataBlock )?
    #
    # @example SPARQL Grammar (ValuesClause)
    #   PREFIX dc:   <http://purl.org/dc/elements/1.1/> 
    #   PREFIX :     <http://example.org/book/> 
    #   PREFIX ns:   <http://example.org/ns#> 
    #   SELECT ?book ?title ?price {
    #      ?book dc:title ?title ;
    #            ns:price ?price .
    #   }
    #   VALUES ?book { :book1 }
    #
    # @example SSE (ValuesClause)
    #   (prefix ((dc: <http://purl.org/dc/elements/1.1/>)
    #            (: <http://example.org/book/>)
    #            (ns: <http://example.org/ns#>))
    #    (project (?book ?title ?price)
    #     (join
    #      (bgp (triple ?book dc:title ?title) (triple ?book ns:price ?price))
    #      (table (vars ?book) (row (?book :book1)))) ))
    #
    # [61]  InlineData              ::= 'VALUES' DataBlock
    #
    # @example SPARQL Grammar (InlineData)
    #   PREFIX dc:   <http://purl.org/dc/elements/1.1/> 
    #   PREFIX :     <http://example.org/book/> 
    #   PREFIX ns:   <http://example.org/ns#> 
    #   
    #   SELECT ?book ?title ?price
    #   {
    #      VALUES ?book { :book1 }
    #      ?book dc:title ?title ;
    #            ns:price ?price .
    #   }
    #
    # @example SSE (InlineData)
    #   (prefix ((dc: <http://purl.org/dc/elements/1.1/>)
    #            (: <http://example.org/book/>)
    #            (ns: <http://example.org/ns#>))
    #    (project (?book ?title ?price)
    #     (join
    #      (table (vars ?book) (row (?book :book1)))
    #      (bgp (triple ?book dc:title ?title) (triple ?book ns:price ?price))) ))
    #
    # @example empty table
    #     (table unit)
    #
    # @see https://www.w3.org/TR/2013/REC-sparql11-query-20130321/#inline-data
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
      # @see    https://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      def execute(queryable, **options, &block)
        @solutions = RDF::Query::Solutions()
        Array(operands[1..-1]).each do |row|
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

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        str = "VALUES (#{Array(operands.first)[1..-1].map { |e| e.to_sparql(**options) }.join(' ')}) {\n"
        operands[1..-1].each do |row|
          line = '('
          row[1..-1].each do |col|
            line << "#{col[1].to_sparql(**options)} "
          end
          line = line.chop
          line << ")\n"

          str << line
        end

        str << "}\n"
        str
      end
    end # Table
  end # Operator
end; end # SPARQL::Algebra
