module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL `bnode` operator.
    #
    # The BNODE function constructs a blank node that is distinct from all blank nodes in the dataset being queried and distinct from all blank nodes created by calls to this constructor for other query solutions. If the no argument form is used, every call results in a distinct blank node. If the form with a simple literal is used, every call results in distinct blank nodes for different simple literals, and the same blank node for calls with the same simple literal within expressions for one solution mapping.
    #
    # @example
    #     (prefix ((: <http://example.org/>)
    #              (xsd: <http://www.w3.org/2001/XMLSchema#>))
    #       (project (?s1 ?s2 ?b1 ?b2)
    #         (extend ((?b1 (bnode ?s1)) (?b2 (bnode ?s2)))
    #           (filter (exprlist (|| (= ?a :s1) (= ?a :s3)) (|| (= ?b :s1) (= ?b :s3)))
    #             (bgp
    #               (triple ?a :str ?s1)
    #               (triple ?b :str ?s2)
    #             )))))
    #
    # @see http://www.w3.org/TR/sparql11-query/#func-bnode
    class BNode < Operator::Unary
      include Evaluatable

      NAME = :bnode


      ##
      # Initializes a new operator instance.
      #
      # @param  [RDF::Literal] literal (false)
      # @param  [Hash{Symbol => Object}] options
      #   any additional options (see {Operator#initialize})
      # @raise  [TypeError] if any operand is invalid
      def initialize(literal = false, options = {})
        super
      end

      ##
      # Evaluates this operator using the given variable `bindings`.
      #
      # @param  [RDF::Query::Solution] bindings
      #   a query solution containing zero or more variable bindings
      # @param [Hash{Symbol => Object}] options ({})
      #   options passed from query
      # @return [RDF::Term]
      def evaluate(bindings, options = {})
        args = operands.map { |operand| operand.evaluate(bindings, options.merge(depth: options[:depth].to_i + 1)) }
        apply(args.first, bindings)
      end

      ##
      # The BNODE function constructs a blank node that is distinct from all blank nodes in the dataset being queried and distinct from all blank nodes created by calls to this constructor for other query solutions. If the no argument form is used, every call results in a distinct blank node. If the form with a simple literal is used, every call results in distinct blank nodes for different simple literals, and the same blank node for calls with the same simple literal within expressions for one solution mapping.
      #
      # This functionality is compatible with the treatment of blank nodes in SPARQL CONSTRUCT templates.
      #
      # @param  [RDF::Literal] literal (nil)
      # @param  [RDF::Query::Solution, #[]] bindings
      #   a query solution containing zero or more variable bindings
      # @return [RDF::Node] 
      # @raise  [TypeError] if the operand is not a simple literal or nil
      def apply(literal, bindings)
        @@bnode_base ||= "b0"
        @@bindings ||= bindings
        @@bnodes ||= {}

        if literal == RDF::Literal::FALSE
          l, @@bnode_base = @@bnode_base, @@bnode_base.succ
          RDF::Node.new(l)
        else
          raise TypeError, "expected an simple literal, but got #{literal.inspect}" unless literal.literal? && literal.simple?
          # Return the same BNode if used with the same binding
          @@bnodes, @@bindings = {}, bindings unless @@bindings == bindings
          @@bnodes[literal.to_s.to_sym] ||= begin
            l, @@bnode_base = @@bnode_base, @@bnode_base.succ
            RDF::Node.new(l)
          end
        end
      end

      ##
      # Returns the SPARQL S-Expression (SSE) representation of this expression.
      #
      # Remove the optional argument.
      #
      # @return [Array] `self`
      # @see    http://openjena.org/wiki/SSE
      def to_sxp_bin
        [NAME] + operands.reject {|o| o == false}
      end
    end # BNode
  end # Operator
end; end # SPARQL::Algebra
