module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL `concat` operator.
    #
    # The CONCAT function corresponds to the XPath fn:concat function. The function accepts string literals as arguments.
    #
    # [121] BuiltInCall ::= ... 'CONCAT' ExpressionList 
    #
    # @example SPARQL Grammar
    #   PREFIX : <http://example.org/>
    #   SELECT (CONCAT(?str1,?str2) AS ?str) WHERE {
    #     :s6 :str ?str1 .
    #     :s7 :str ?str2 .
    #   }
    #
    # @example SSE
    #   (prefix
    #    ((: <http://example.org/>))
    #    (project (?str)
    #     (extend ((?str (concat ?str1 ?str2)))
    #      (bgp
    #       (triple :s6 :str ?str1)
    #       (triple :s7 :str ?str2)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-concat
    # @see https://www.w3.org/TR/xpath-functions/#func-concat
    class Concat < Operator
      include Evaluatable

      NAME = :concat

      ##
      # The lexical form of the returned literal is obtained by concatenating the lexical forms of its inputs. If all input literals are typed literals of type xsd:string, then the returned literal is also of type `xsd:string`, if all input literals are plain literals with identical language tag, then the returned literal is a plain literal with the same language tag, in all other cases, the returned literal is a simple literal.
      #
      # @example
      #     concat("foo", "bar")                         #=> "foobar"
      #     concat("foo"@en, "bar"@en)                   #=> "foobar"@en
      #     concat("foo"^^xsd:string, "bar"^^xsd:string) #=> "foobar"^^xsd:string
      #     concat("foo", "bar"^^xsd:string)             #=> "foobar"
      #     concat("foo"@en, "bar")                      #=> "foobar"
      #     concat("foo"@en, "bar"^^xsd:string)          #=> "foobar"
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @return [RDF::Term]
      # @raise  [TypeError] if any operand is not a literal
      def evaluate(bindings, **options)
        ops = operands.map {|op| op.evaluate(bindings, **options.merge(depth: options[:depth].to_i + 1))}

        # rdf:nil is like empty string
        if ops == [RDF.nil]
          return RDF::Literal.new("")
        end

        raise TypeError, "expected all plain literal operands" unless ops.all? {|op| op.literal? && op.plain?}

        ops.inject do |memo, op|
          case
          when memo.datatype == RDF::XSD.string && op.datatype == RDF::XSD.string
            RDF::Literal.new("#{memo}#{op}", datatype: RDF::XSD.string)
          when memo.has_language? && memo.language == op.language
            RDF::Literal.new("#{memo}#{op}", language: memo.language)
          else
            RDF::Literal.new("#{memo}#{op}")
          end
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "CONCAT(#{operands.to_sparql(delimiter: ', ', **options)})"
      end
    end # Concat
  end # Operator
end; end # SPARQL::Algebra
