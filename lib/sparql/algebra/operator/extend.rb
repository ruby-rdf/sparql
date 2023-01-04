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
    # @example SSE (cast as boolean)
    #   (prefix ((: <http://example.org/>)
    #            (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
    #            (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #    (project (?a ?v ?boolean)
    #     (extend ((?boolean (xsd:boolean ?v)))
    #      (bgp (triple ?a :p ?v)))))
    #
    # @example SPARQL Grammar (inner bind)
    #   PREFIX : <http://example.org/> 
    #   
    #   SELECT ?z ?s1
    #   {
    #     ?s ?p ?o .
    #     BIND(?o+1 AS ?z)
    #     ?s1 ?p1 ?z
    #   }
    #
    # @example SSE (inner bind)
    #   (prefix ((: <http://example.org/>))
    #    (project (?z ?s1)
    #     (join
    #      (extend ((?z (+ ?o 1)))
    #       (bgp (triple ?s ?p ?o)))
    #     (bgp (triple ?s1 ?p1 ?z)))))
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
        @solutions = operand(1).execute(queryable, **options.merge(depth: options[:depth].to_i + 1))
        @solutions.each do |solution|
          # Re-bind to bindings, if defined, as they might not be found in solution
          options[:bindings].each_binding do |name, value|
            solution[name] = value if operands.first.variables.include?(name)
          end if options[:bindings] && operands.first.respond_to?(:variables)

          debug(options) {"===> soln #{solution.to_h.inspect}"}
          operand(0).each do |(var, expr)|
            begin
              val = expr.evaluate(solution, queryable: queryable,
                                            **options.merge(depth: options[:depth].to_i + 1))
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
      #
      # Also, variables used in a binding expression must be projected by the query.
      def validate!
        bind_vars = operand(0).map(&:first).map(&:name)
        query_vars = operand(1).variables.keys
        
        unless (bind_vars.compact & query_vars.compact).empty?
          raise ArgumentError,
               "bound variable used in query: #{(bind_vars.compact & query_vars.compact).to_sse}"
        end

        # Special case for group variables
        if operands.last.is_a?(Group)
          bind_expr_vars = operand(0).map(&:last).variables.keys
          group_vars = operands.last.variables.keys
          group_internal_vars = operands.last.internal_variables.keys

          bind_expr_vars.each do |v|
            raise ArgumentError,
                 "extension expression uses variable not in scope: #{v}" if
                 group_internal_vars.include?(v) &&
                 !group_vars.include?(v)
          end
        end

        super
      end

      ##
      # The variables used in the extension.
      # Includes extended variables.
      #
      # @return [Hash{Symbol => RDF::Query::Variable}]
      def variables
        operands.first.
          map(&:first).
          map(&:variables).
          inject(operands.last.variables) {|memo, h| memo.merge(h)}
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
          # Use string/name of variable "as" to aid in later matching
          memo.merge(as.to_s => expression)
        end

        # Merge any inherited extensions from options
        extensions = options.delete(:extensions).merge(extensions) if options.key?(:extensions)
        operands.last.to_sparql(extensions: extensions, **options)
      end
    end # Extend
  end # Operator
end; end # SPARQL::Algebra
