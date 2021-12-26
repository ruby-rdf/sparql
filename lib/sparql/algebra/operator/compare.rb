module SPARQL; module Algebra
  class Operator
    ##
    # A SPARQL relational `<=>` comparison operator.
    #
    # @example
    #   (<=> ?x ?y)
    #
    # @see https://www.w3.org/TR/sparql11-query/#OperatorMapping
    # @see https://www.w3.org/TR/xpath-functions/#func-compare
    class Compare < Operator::Binary
      include Evaluatable

      NAME = :<=>

      ##
      # Returns -1, 0, or 1, depending on whether the first operand is
      # respectively less than, equal to, or greater than the second
      # operand.
      #
      # SPARQL also fixes an order between some kinds of RDF terms that would not otherwise be ordered:
      #
      #   (Lowest) no value assigned to the variable or expression in this solution.
      #   Blank nodes
      #   IRIs
      #   RDF literals
      #
      # @param  [RDF::Literal] left
      #   a literal
      # @param  [RDF::Literal] right
      #   a literal
      # @return [RDF::Literal::Integer] `-1`, `0`, or `1`
      # @raise  [TypeError] if either operand is not a term
      def apply(left, right, **options)
        RDF::Literal(spaceship(left, right, **options))
      end

      ##
      #
      # Returns a partial SPARQL grammar for this operator.
      #
      # @return [String]
      def to_sparql(**options)
        "(#{operands.first.to_sparql(**options)} #{self.class.const_get(:NAME)} #{operands.last.to_sparql(**options)})"
      end

    private
      # Define <=> as private for recursive statements
      def spaceship(left, right, **options)
        case
        # @see https://www.w3.org/TR/sparql11-query/#OperatorMapping
        # @see https://www.w3.org/TR/sparql11-query/#modOrderBy
        when left.is_a?(RDF::Literal) && right.is_a?(RDF::Literal)
          # @see https://www.w3.org/TR/xpath-functions/#string-compare
          # @see https://www.w3.org/TR/xpath-functions/#comp.numeric
          # @see https://www.w3.org/TR/xpath-functions/#op.boolean
          # @see https://www.w3.org/TR/xpath-functions/#comp.duration.datetime
          left <=> right
        when left.is_a?(RDF::URI) && right.is_a?(RDF::URI)
          raise TypeError, "Comparing IRIs not supported" unless options[:order_by] || left == right
          # Pairs of IRIs are ordered by comparing them as simple literals.
          left.to_s <=> right.to_s
        when left.is_a?(RDF::Node) && right.is_a?(RDF::Node)
          raise TypeError, "Comparing Blank nodes not supported" unless options[:order_by] || left == right
          # BNode comparison is undefined.
          left == right ? 0 : 1
        when left.nil? && right.nil?
          0

        when left.is_a?(RDF::Statement) && right.is_a?(RDF::Statement)
          v = spaceship(left.subject, right.subject, **options)
          v = spaceship(left.predicate, right.predicate, **options) if v == 0
          v = spaceship(left.object, right.object, **options) if v == 0
          v
        when left.is_a?(RDF::Statement) && right.is_a?(RDF::Term)
          raise TypeError, "Comparing statement with #{right.inspect}" unless options[:order_by]
          1
        when right.is_a?(RDF::Statement) && left.is_a?(RDF::Term)
          raise TypeError, "Comparing statement with #{left.inspect}" unless options[:order_by]
          -1

        # SPARQL also fixes an order between some kinds of RDF terms that would not otherwise be ordered:

        when left.nil? && !right.nil?
          -1
        when right.nil?
          1

        when left.is_a?(RDF::Node) && right.is_a?(RDF::Term)
          raise TypeError, "Comparing Blank nodes not supported" unless options[:order_by]
          # Nodes lower than other terms
          -1
        when right.is_a?(RDF::Node) && left.is_a?(RDF::Term)
          raise TypeError, "Comparing Blank nodes not supported" unless options[:order_by]
          1

        when left.is_a?(RDF::URI) && right.is_a?(RDF::Term)
          raise TypeError, "Comparing IRIs not supported" unless options[:order_by]
          # IRIs lower than terms other than nodes
          -1
        when right.is_a?(RDF::URI) && left.is_a?(RDF::Term)
          raise TypeError, "Comparing IRIs not supported" unless options[:order_by]
          1
        else raise TypeError, "expected two RDF::Term operands, but got #{left.inspect} and #{right.inspect}"
        end
      end
    end # Compare
  end # Operator
end; end # SPARQL::Algebra
