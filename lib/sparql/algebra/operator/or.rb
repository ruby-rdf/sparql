module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL logical `or` operator.
    #
    # [111] ConditionalOrExpression ::= ConditionalAndExpression ( '||' ConditionalAndExpression )*
    #
    # @example SPARQL Grammar
    #   PREFIX  xsd: <http://www.w3.org/2001/XMLSchema#>
    #   PREFIX  : <http://example.org/ns#>
    #   SELECT  ?a
    #   WHERE {
    #     ?a :p ?v . 
    #     FILTER ("false"^^xsd:boolean || ?v) .
    #   }
    #
    # @example SSE
    #   (prefix ((xsd: <http://www.w3.org/2001/XMLSchema#>)
    #            (: <http://example.org/ns#>))
    #    (project (?a)
    #     (filter (|| false ?v)
    #      (bgp (triple ?a :p ?v)))))
    #
    # @see https://www.w3.org/TR/sparql11-query/#func-logical-or
    # @see https://www.w3.org/TR/sparql11-query/#evaluation
    class Or < Operator::Binary
      include Evaluatable

      NAME = [:'||', :or]

      ##
      # Initializes a new operator instance.
      #
      # @param  [RDF::Literal::Boolean] left
      #   the left operand
      # @param  [RDF::Literal::Boolean] right
      #   the right operand
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      # @raise  [TypeError] if any operand is invalid
      def initialize(left, right, **options)
        super
      end

      ##
      # Returns the logical `OR` of the left operand and the right operand.
      #
      # Note that this operator operates on the effective boolean value
      # (EBV) of its operands.
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @return [RDF::Literal::Boolean] `true` or `false`
      # @raise  [TypeError] if the operands could not be coerced to a boolean literal
      def evaluate(bindings, **options)
        begin
          left = boolean(operand(0).evaluate(bindings, **options.merge(depth: options[:depth].to_i + 1))).true?
        rescue TypeError
          left = nil
        end
        
        begin
          right = boolean(operand(1).evaluate(bindings, **options.merge(depth: options[:depth].to_i + 1))).true?
        rescue TypeError
          right = nil
        end

        # From https://www.w3.org/TR/sparql11-query/#evaluation
        # A logical-or that encounters an error on only one branch will return TRUE if the other branch is TRUE
        # and an error if the other branch is FALSE.
        case
        when left.nil? && right.nil? then raise(TypeError)
        when left.nil?               then right ? RDF::Literal::TRUE : raise(TypeError)
        when right.nil?              then left ? RDF::Literal::TRUE : raise(TypeError)
        else                              RDF::Literal(left || right)
        end
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(#{operands.first.to_sparql(**options)} || #{operands.last.to_sparql(**options)})"
      end
    end # Or
  end # Operator
end; end # SPARQL::Algebra
