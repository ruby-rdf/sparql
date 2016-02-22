require 'rdf' # @see http://rubygems.org/gems/rdf
require 'rdf/xsd'

module SPARQL
  ##
  # A SPARQL algebra for RDF.rb.
  #
  # Parses Sparql S-Expressions (SSE) into SPARQL Algebra operators.
  #
  # Operators implementing {SPARQL::Algebra::Query#execute} may directly
  # execute an object implementing {RDF::Queryable}, and so may be treated
  # equivalently to {RDF::Query}.
  #
  # Operators implementing {SPARQL::Algebra::Expression#evaluate} may be
  # evaluated with RDF::Query::Solution bindings to yield an appropriate result.
  #
  # An entire SSE expression is parsed into a recursive set of {SPARQL::Algebra::Operator}
  # instances, with each operand representing an additional operator.
  #
  # {RDF::Query} and {RDF::Query::Pattern} are used as primitives for `bgp` and `triple` expressions.
  #
  # # Queries
  # 
  #     require 'sparql/algebra'
  # 
  #     include SPARQL::Algebra
  # 
  # ## Basic Query
  #     BASE <http://example.org/x/> 
  #     PREFIX : <>
  # 
  #     SELECT * WHERE { :x ?p ?v } 
  # 
  # is equivalent to
  # 
  #     (base <http://example.org/x/>
  #       (prefix ((: <>))
  #         (bgp (triple :x ?p ?v))))
  # 
  # ## Prefixes
  # 
  #     PREFIX ns: <http://example.org/ns#>
  #     PREFIX x:  <http://example.org/x/>
  # 
  #     SELECT * WHERE { x:x ns:p ?v } 
  # 
  # is equivalent to
  # 
  #     (prefix ((ns: <http://example.org/ns#>)
  #              (x: <http://example.org/x/>))
  #       (bgp (triple x:x ns:p ?v)))
  # 
  # ## Ask
  # 
  #     PREFIX :  <http://example/>
  # 
  #     ASK WHERE { :x :p ?x } 
  # 
  # is equivalent to
  # 
  #     (prefix ((: <http://example/>))
  #       (ask
  #         (bgp (triple :x :p ?x))))
  # 
  # ## Datasets
  # 
  #     PREFIX : <http://example/> 
  # 
  #     SELECT * 
  #     FROM <data-g1.ttl>
  #     FROM NAMED <data-g2.ttl>
  #     { ?s ?p ?o }
  # 
  # is equivalent to
  # 
  #     (prefix ((: <http://example/>))
  #       (dataset (<data-g1.ttl> (named <data-g2.ttl>))
  #         (bgp (triple ?s ?p ?o))))
  # 
  # ## Join
  # 
  #     PREFIX : <http://example/> 
  # 
  #     SELECT * 
  #     { 
  #        ?s ?p ?o
  #        GRAPH ?g { ?s ?q ?v }
  #     }
  # 
  # is equivalent to
  # 
  #     (prefix ((: <http://example/>))
  #       (join
  #         (bgp (triple ?s ?p ?o))
  #         (graph ?g
  #           (bgp (triple ?s ?q ?v)))))
  # 
  # ## Union
  # 
  #     PREFIX : <http://example/> 
  # 
  #     SELECT * 
  #     { 
  #        { ?s ?p ?o }
  #       UNION
  #        { GRAPH ?g { ?s ?p ?o } }
  #     }
  # 
  # is equivalent to
  # 
  #     (prefix ((: <http://example/>))
  #       (union
  #         (bgp (triple ?s ?p ?o))
  #         (graph ?g
  #           (bgp (triple ?s ?p ?o)))))
  # 
  # ## LeftJoin
  # 
  #     PREFIX :    <http://example/>
  # 
  #     SELECT *
  #     { 
  #       ?x :p ?v .
  #       OPTIONAL
  #       { 
  #         ?y :q ?w .
  #         FILTER(?v=2)
  #       }
  #     }
  # 
  # is equivalent to
  # 
  #     (prefix ((: <http://example/>))
  #       (leftjoin
  #         (bgp (triple ?x :p ?v))
  #         (bgp (triple ?y :q ?w))
  #         (= ?v 2)))
  # 
  # # Expressions
  # 
  # ## Constructing operator expressions manually
  # 
  #     Operator(:isBlank).new(RDF::Node(:foobar)).to_sxp                        #=> "(isBlank _:foobar)"
  #     Operator(:isIRI).new(RDF::URI('http://rdf.rubyforge.org/')).to_sxp       #=> "(isIRI <http://rdf.rubyforge.org/>)"
  #     Operator(:isLiteral).new(RDF::Literal(3.1415)).to_sxp                    #=> "(isLiteral 3.1415)"
  #     Operator(:str).new(Operator(:datatype).new(RDF::Literal(3.1415))).to_sxp #=> "(str (datatype 3.1415))"
  # 
  # ## Constructing operator expressions using SSE forms
  # 
  #     SPARQL::Algebra::Expression[:isBlank, RDF::Node(:foobar)].to_sxp                          #=> "(isBlank _:foobar)"
  #     SPARQL::Algebra::Expression[:isIRI, RDF::URI('http://rdf.rubyforge.org/')].to_sxp         #=> "(isIRI <http://rdf.rubyforge.org/>)"
  #     SPARQL::Algebra::Expression[:isLiteral, RDF::Literal(3.1415)].to_sxp                      #=> "(isLiteral 3.1415)"
  #     SPARQL::Algebra::Expression[:str, [:datatype, RDF::Literal(3.1415)]].to_sxp               #=> "(str (datatype 3.1415))"
  # 
  # ## Constructing operator expressions using SSE strings
  # 
  #     SPARQL::Algebra::Expression.parse('(isBlank _:foobar)')
  #     SPARQL::Algebra::Expression.parse('(isIRI <http://rdf.rubyforge.org/>)')
  #     SPARQL::Algebra::Expression.parse('(isLiteral 3.1415)')
  #     SPARQL::Algebra::Expression.parse('(str (datatype 3.1415))')
  # 
  # ## Evaluating operators standalone
  # 
  #     Operator(:isBlank).evaluate(RDF::Node(:foobar))                          #=> RDF::Literal::TRUE
  #     Operator(:isIRI).evaluate(RDF::Vocab::DC.title)                                 #=> RDF::Literal::TRUE
  #     Operator(:isLiteral).evaluate(RDF::Literal(3.1415))                      #=> RDF::Literal::TRUE
  # 
  # ## Optimizing expressions containing constant subexpressions
  # 
  #     SPARQL::Algebra::Expression.parse('(sameTerm ?var ?var)').optimize            #=> RDF::Literal::TRUE
  #     SPARQL::Algebra::Expression.parse('(* -2 (- (* (+ 1 2) (+ 3 4))))').optimize  #=> RDF::Literal(42)
  # 
  # ## Evaluating expressions on a solution sequence
  # 
  #     # Find all people and their names & e-mail addresses:
  #     solutions = RDF::Query.execute(RDF::Graph.load('etc/doap.ttl')) do |query|
  #       query.pattern [:person, RDF.type,  RDF::Vocab::FOAF.Person]
  #       query.pattern [:person, RDF::Vocab::FOAF.name, :name]
  #       query.pattern [:person, RDF::Vocab::FOAF.mbox, :email], optional: true
  #     end
  # 
  #     # Find people who have a name but don't have a known e-mail address:
  #     expression = SPARQL::Algebra::Expression[:not, [:bound, Variable(:email)]]    # ...or just...
  #     expression = SPARQL::Algebra::Expression.parse('(not (bound ?email))')
  #     solutions.filter!(expression)
  # 
  # @example Optimizations
  # 
  # Some very simple optimizations are currently implemented for `FILTER`
  # expressions. Use the following to obtain optimized SSE forms:
  # 
  #     SPARQL::Algebra::Expression.parse(sse).optimize.to_sxp_bin
  # 
  # ## Constant comparison folding
  # 
  #     (sameTerm ?x ?x)   #=> true
  # 
  # ## Constant arithmetic folding
  # 
  #     (!= ?x (+ 123))    #=> (!= ?x 123)
  #     (!= ?x (- -1.0))   #=> (!= ?x 1.0)
  #     (!= ?x (+ 1 2))    #=> (!= ?x 3)
  #     (!= ?x (- 4 5))    #=> (!= ?x -1)
  #     (!= ?x (* 6 7))    #=> (!= ?x 42)
  #     (!= ?x (/ 0 0.0))  #=> (!= ?x NaN)
  # 
  # ## Memoization
  # 
  # Expressions can optionally be [memoized][memoization], which can speed up
  # repeatedly executing the expression on a solution sequence:
  # 
  #     SPARQL::Algebra::Expression.parse(sse, memoize: true)
  #     Operator.new(*operands, memoize: true)
  # 
  # Memoization is implemented using RDF.rb's [RDF::Util::Cache][] utility
  # library, a weak-reference cache that allows values contained in the cache to
  # be garbage collected. This allows the cache to dynamically adjust to
  # changing memory conditions, caching more objects when memory is plentiful,
  # but evicting most objects if memory pressure increases to the point of
  # scarcity.
  # 
  # [memoization]:      http://en.wikipedia.org/wiki/Memoization
  # [RDF::Util::Cache]: http://rdf.rubyforge.org/RDF/Util/Cache.html
  # 
  # ## Documentation
  # 
  # * {SPARQL::Algebra}
  #   * {SPARQL::Algebra::Aggregate}
  #   * {SPARQL::Algebra::Evaluatable}
  #   * {SPARQL::Algebra::Expression}
  #   * {SPARQL::Algebra::Query}
  #   * {SPARQL::Algebra::Update}
  #   * {SPARQL::Algebra::Operator}
  #     * {SPARQL::Algebra::Operator::Abs}
  #     * {SPARQL::Algebra::Operator::Add}
  #     * {SPARQL::Algebra::Operator::And}
  #     * {SPARQL::Algebra::Operator::Asc}
  #     * {SPARQL::Algebra::Operator::Ask}
  #     * {SPARQL::Algebra::Operator::Avg}
  #     * {SPARQL::Algebra::Operator::Base}
  #     * {SPARQL::Algebra::Operator::BGP}
  #     * {SPARQL::Algebra::Operator::Bound}
  #     * {SPARQL::Algebra::Operator::Ceil}
  #     * {SPARQL::Algebra::Operator::Clear}
  #     * {SPARQL::Algebra::Operator::Coalesce}
  #     * {SPARQL::Algebra::Operator::Compare}
  #     * {SPARQL::Algebra::Operator::Concat}
  #     * {SPARQL::Algebra::Operator::Construct}
  #     * {SPARQL::Algebra::Operator::Contains}
  #     * {SPARQL::Algebra::Operator::Copy}
  #     * {SPARQL::Algebra::Operator::Count}
  #     * {SPARQL::Algebra::Operator::Create}
  #     * {SPARQL::Algebra::Operator::Dataset}
  #     * {SPARQL::Algebra::Operator::Datatype}
  #     * {SPARQL::Algebra::Operator::Day}
  #     * {SPARQL::Algebra::Operator::Delete}
  #     * {SPARQL::Algebra::Operator::DeleteData}
  #     * {SPARQL::Algebra::Operator::DeleteWhere}
  #     * {SPARQL::Algebra::Operator::Desc}
  #     * {SPARQL::Algebra::Operator::Describe}
  #     * {SPARQL::Algebra::Operator::Distinct}
  #     * {SPARQL::Algebra::Operator::Divide}
  #     * {SPARQL::Algebra::Operator::Drop}
  #     * {SPARQL::Algebra::Operator::EncodeForURI}
  #     * {SPARQL::Algebra::Operator::Equal}
  #     * {SPARQL::Algebra::Operator::Exprlist}
  #     * {SPARQL::Algebra::Operator::Extend}
  #     * {SPARQL::Algebra::Operator::Filter}
  #     * {SPARQL::Algebra::Operator::Floor}
  #     * {SPARQL::Algebra::Operator::Graph}
  #     * {SPARQL::Algebra::Operator::GreaterThan}
  #     * {SPARQL::Algebra::Operator::GreaterThanOrEqual}
  #     * {SPARQL::Algebra::Operator::Group}
  #     * {SPARQL::Algebra::Operator::GroupConcat}
  #     * {SPARQL::Algebra::Operator::Hours}
  #     * {SPARQL::Algebra::Operator::If}
  #     * {SPARQL::Algebra::Operator::In}
  #     * {SPARQL::Algebra::Operator::Insert}
  #     * {SPARQL::Algebra::Operator::InsertData}
  #     * {SPARQL::Algebra::Operator::IRI}
  #     * {SPARQL::Algebra::Operator::IsBlank}
  #     * {SPARQL::Algebra::Operator::IsIRI}
  #     * {SPARQL::Algebra::Operator::IsLiteral}
  #     * {SPARQL::Algebra::Operator::IsNumeric}
  #     * {SPARQL::Algebra::Operator::Join}
  #     * {SPARQL::Algebra::Operator::Lang}
  #     * {SPARQL::Algebra::Operator::LangMatches}
  #     * {SPARQL::Algebra::Operator::LeftJoin}
  #     * {SPARQL::Algebra::Operator::LessThan}
  #     * {SPARQL::Algebra::Operator::LessThanOrEqual}
  #     * {SPARQL::Algebra::Operator::Max}
  #     * {SPARQL::Algebra::Operator::MD5}
  #     * {SPARQL::Algebra::Operator::Min}
  #     * {SPARQL::Algebra::Operator::Minus}
  #     * {SPARQL::Algebra::Operator::Minutes}
  #     * {SPARQL::Algebra::Operator::Modify}
  #     * {SPARQL::Algebra::Operator::Month}
  #     * {SPARQL::Algebra::Operator::Move}
  #     * {SPARQL::Algebra::Operator::Multiply}
  #     * {SPARQL::Algebra::Operator::Negate}
  #     * {SPARQL::Algebra::Operator::Not}
  #     * {SPARQL::Algebra::Operator::NotEqual}
  #     * {SPARQL::Algebra::Operator::NotExists}
  #     * {SPARQL::Algebra::Operator::NotIn}
  #     * {SPARQL::Algebra::Operator::Now}
  #     * {SPARQL::Algebra::Operator::Or}
  #     * {SPARQL::Algebra::Operator::Order}
  #     * {SPARQL::Algebra::Operator::Plus}
  #     * {SPARQL::Algebra::Operator::Prefix}
  #     * {SPARQL::Algebra::Operator::Project}
  #     * {SPARQL::Algebra::Operator::Rand}
  #     * {SPARQL::Algebra::Operator::Reduced}
  #     * {SPARQL::Algebra::Operator::Regex}
  #     * {SPARQL::Algebra::Operator::Replace}
  #     * {SPARQL::Algebra::Operator::Round}
  #     * {SPARQL::Algebra::Operator::SameTerm}
  #     * {SPARQL::Algebra::Operator::Sample}
  #     * {SPARQL::Algebra::Operator::Seconds}
  #     * {SPARQL::Algebra::Operator::SHA1}
  #     * {SPARQL::Algebra::Operator::SHA256}
  #     * {SPARQL::Algebra::Operator::SHA384}
  #     * {SPARQL::Algebra::Operator::SHA512}
  #     * {SPARQL::Algebra::Operator::Slice}
  #     * {SPARQL::Algebra::Operator::Str}
  #     * {SPARQL::Algebra::Operator::StrAfter}
  #     * {SPARQL::Algebra::Operator::StrBefore}
  #     * {SPARQL::Algebra::Operator::StrDT}
  #     * {SPARQL::Algebra::Operator::StrEnds}
  #     * {SPARQL::Algebra::Operator::StrLang}
  #     * {SPARQL::Algebra::Operator::StrLen}
  #     * {SPARQL::Algebra::Operator::StrStarts}
  #     * {SPARQL::Algebra::Operator::StrUUID}
  #     * {SPARQL::Algebra::Operator::SubStr}
  #     * {SPARQL::Algebra::Operator::Subtract}
  #     * {SPARQL::Algebra::Operator::Sum}
  #     * {SPARQL::Algebra::Operator::Table}
  #     * {SPARQL::Algebra::Operator::Timezone}
  #     * {SPARQL::Algebra::Operator::TZ}
  #     * {SPARQL::Algebra::Operator::Ucase}
  #     * {SPARQL::Algebra::Operator::Union}
  #     * {SPARQL::Algebra::Operator::Update}
  #     * {SPARQL::Algebra::Operator::Using}
  #     * {SPARQL::Algebra::Operator::UUID}
  #     * {SPARQL::Algebra::Operator::With}
  #     * {SPARQL::Algebra::Operator::Year}
  # 
  # TODO
  # ====
  # * Operator#optimize needs to be completed and tested.
  # 
  # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
  module Algebra
    include RDF

    autoload :Aggregate,   'sparql/algebra/aggregate'
    autoload :Evaluatable, 'sparql/algebra/evaluatable'
    autoload :Expression,  'sparql/algebra/expression'
    autoload :Operator,    'sparql/algebra/operator'
    autoload :Query,       'sparql/algebra/query'
    autoload :Update,      'sparql/algebra/update'

    ##
    # @example
    #   sse = (prefix ((foaf: <http://xmlns.com/foaf/0.1/>))
    #           (project (?name ?mbox)
    #             (join
    #               (bgp (triple ?x foaf:name ?name))
    #               (bgp (triple ?x foaf:mbox ?mbox)))))
    #   }
    # @param  [String] sse
    #   a SPARQL S-Expression (SSE) string
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see {Operator#initialize})
    # @return [SPARQL::Algebra::Operator]
    def parse(sse, options = {})
      Expression.parse(sse, options)
    end
    module_function :parse

    ##
    # Parses input from the given file name or URL.
    #
    # @param  [String, #to_s] sse
    # @param  [Hash{Symbol => Object}] options
    #   any additional options (see {Operator#initialize})
    # @option options [RDF::URI, #to_s] :base_uri
    #   Base URI used for loading relative URIs.
    #
    # @yield  [expression]
    # @yieldparam  [SPARQL::Algebra::Expression] expression
    # @yieldreturn [void] ignored
    # @return [Expression]
    def open(sse, options = {})
      Expression.open(sse, options)
    end
    module_function :open

    ##
    # @example
    #   Expression(:isLiteral, RDF::Literal(3.1415))
    #
    # @param  [Array] sse
    #   a SPARQL S-Expression (SSE) form
    # @return [SPARQL::Algebra::Expression]
    def Expression(*sse)
      Expression.for(*sse)
    end
    alias_method :Expr, :Expression
    module_function :Expr, :Expression

    ##
    # @example
    #   Operator(:isLiteral)
    #
    # @param  [Symbol, #to_sym] name
    # @return [Class]
    def Operator(name, arity = nil)
      Operator.for(name, arity)
    end
    alias_method :Op, :Operator
    module_function :Op, :Operator

    ##
    # @example
    #   Variable(:foobar)
    #
    # @param  [Symbol, #to_sym] name
    # @return [Variable]
    # @see    http://rdf.rubyforge.org/RDF/Query/Variable.html
    def Variable(name)
      Variable.new(name)
    end
    alias_method :Var, :Variable
    module_function :Var, :Variable

    Variable = RDF::Query::Variable
  end # Algebra
end # SPARQL

require 'sparql/algebra/extensions'
