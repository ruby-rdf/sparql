module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `Extend` operator.
    #
    # Extends a solution
    #
    # [60]  Bind ::= 'BIND' '(' Expression 'AS' Var ')'
    #
    # @example SPARQL Grammar
    #   SELECT ?z
    #   { 
    #     ?x <http://example.org/p> ?o
    #     BIND(?o+10 AS ?z)
    #   }
    #
    # @example SSE
    #   (project (?z)
    #     (extend ((?z (+ ?o 10)))
    #       (bgp (triple ?x <http://example.org/p> ?o))))
    #
    # @example SPARQL Grammar (cast as boolean)
    #   PREFIX : <http://example.org/>
    #   PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
    #   PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
    #   SELECT ?a ?v (xsd:boolean(?v) AS ?boolean)
    #   WHERE { ?a :p ?v . }
    #
    # @example SSE
    #   (prefix ((: <http://example.org/>)
    #            (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
    #            (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (project (?a ?v ?boolean)
    #     (extend ((?boolean (xsd:boolean ?v)))
    #      (bgp (triple ?a :p ?v)))))
    #   
    #
    # @see https://www.w3.org/TR/sparql11-query/#evaluation
    class Extend < Operator::Binary
      include Query
      
      NAME = [:extend]

      ##
      # Let μ be a solution mapping, Ω a multiset of solution mappings, var a variable and expr be an expression, then we define:
      # 
      # Extend(μ, var, expr) = μ ∪ { (var,value) | var not in dom(μ) and value = expr(μ) }
      # 
      # Extend(μ, var, expr) = μ if var not in dom(μ) and expr(μ) is an error
      # 
      # Extend is undefined when var in dom(μ).
      # 
      # Extend(Ω, var, expr) = { Extend(μ, var, expr) | μ in Ω }
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
      # @see https://www.w3.org/TR/sparql11-query/#evaluation
      def execute(queryable, **options, &block)
        debug(options) {"Extend"}
        @solutions = operand(1).execute(queryable, depth: options[:depth].to_i + 1, **options)
        @solutions.each do |solution|
          debug(options) {"===> soln #{solution.to_h.inspect}"}
          operand(0).each do |(var, expr)|
            begin
              val = expr.evaluate(solution, queryable: queryable,
                                            depth: options[:depth].to_i + 1,
                                            **options)
              debug(options) {"===> + #{var} => #{val.inspect}"}
              val = val.dup.bind(solution) if val.is_a?(RDF::Query::Pattern)
              solution.bindings[var.to_sym] = val
            rescue TypeError => e
              # Evaluates to error, ignore
              debug(options) {"===> #{var} error: #{e.message}"}
            end
          end
        end
        @solutions.each(&block) if block_given?
        @solutions
      end

      # The variable introduced by the BIND clause must not have been used in the group graph pattern up to the point of use in BIND
      def validate!
        bind_vars = operand(0).map(&:first).map(&:name)
        query_vars = operand(1).vars.map(&:name)
        
        unless (bind_vars.compact & query_vars.compact).empty?
          raise ArgumentError,
               "bound variable used in query: #{(bind_vars.compact & query_vars.compact).to_sse}"
        end
        super
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # Extracts bindings.
      #
      # @return [String]
      def to_sparql(**options)
        extensions = operands.first.inject({}) do |memo, (as, expression)|
          # Individual entries may be function calls
          expression = SerializerHelper::FunctionCall.new(*expression) if expression.is_a?(Array)
          memo.merge(as => expression)
        end

        # Merge any inherited extensions from options
        extensions = options.delete(:extensions).merge(extensions) if options.key?(:extensions)
        operands.last.to_sparql(extensions: extensions, **options)
      end
    end # Extend
  end # Operator
end; end # SPARQL::Algebra
