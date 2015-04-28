module SPARQL; module Algebra
  class Operator

    ##
    # The SPARQL UPDATE `add` operator.
    #
    # @example
    #   (add default <a>)
    #
    # @see http://www.w3.org/TR/sparql11-update/#add
    class Add < Operator
      NAME = [:add]

    end # Add
  end # Operator
end; end # SPARQL::Algebra
