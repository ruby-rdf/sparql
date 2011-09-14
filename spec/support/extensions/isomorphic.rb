require 'digest/sha1'
require 'rdf'
require 'rdf/ntriples'

class RDF::Query
  ##
  # Isomorphism for rdf.rb Solutions
  #
  # RDF::Query::Solutions::Isomorphic provides the functions isomorphic_with and bijection_to for RDF::Query::Solutions.
  #
  # Variation on RDF::Isomorphic for solutions
  # Same basic idea, but instead of solutions, we close over solutions with
  # multiple variables
  #
  # @see http://rdf.rubyforge.org
  # @see http://rdf.rubyforge.org/isomorphic
  class Solutions

    # Returns `true` if this RDF::Solutions is isomorphic with another.
    #
    # Takes a :canonicalize => true argument.  If true, RDF::Literals will be
    # canonicalized while producing a bijection.  This results in broader
    # matches for isomorphism in the case of equivalent literals with different
    # representations.
    #
    # @param opts [Hash<Symbol => Any>] options
    # @param other [RDF::Query::Solutions]
    # @return [Boolean]
    # @example
    #     solutions_a.isomorphic_with solutions_b #=> true
    def isomorphic_with?(other, opts = {})
      !(bijection_to(other, opts).nil?)
    end

    alias_method :isomorphic?, :isomorphic_with?

    # Returns a hash of RDF::Nodes => RDF::Nodes representing an isomorphic
    # bijection of this RDF::Query::Solutions to another RDF::Query::Solutions blank
    # nodes, or nil if a bijection cannot be found.
    #
    # Takes a :canonicalize => true argument.  If true, RDF::Literals will be
    # canonicalized while producing a bijection.  This results in broader
    # matches for isomorphism in the case of equivalent literals with different
    # representations.
    #
    # @example
    #     repository_a.bijection_to repository_b
    # @param other [RDF::Query::Solutions]
    # @param opts [Hash<Symbol => Any>] options
    # @return [Hash, nil]
    def bijection_to(other, opts = {})
    
      grounded_solutions_match = (count == other.count)

      grounded_solutions_match &&= each.all? do | solution |
        solution.has_blank_nodes? || other.include?(solution)
      end

      if grounded_solutions_match
        # blank_stmts and other_blank_stmts are just a performance
        # consideration--we could just as well pass in self and other.  But we
        # will be iterating over this list quite a bit during the algorithm, so
        # we break it down to the parts we're interested in.
        blank_solutions = find_all { |solution| solution.has_blank_nodes? }
        other_blank_solutions = other.find_all { |solution| solution.has_blank_nodes? }

        nodes = RDF::Query::Solutions.blank_nodes_in(blank_solutions)
        other_nodes = RDF::Query::Solutions.blank_nodes_in(other_blank_solutions)
        build_bijection_to blank_solutions, nodes, other_blank_solutions, other_nodes, {}, {}, opts
      else
        nil
      end
    end

    # Returns a new RDF::Query::Solutions with BNodes substituted using the result
    # of #bijection_to.
    #
    # @return [RDF::Query::Solutions]
    def map_nodes!(bijection)
      self.each do |solution|
        solution.each_binding do |name, value|
          solution[name] = bijection.fetch(value, value)
        end
      end
    end
    
    def map_nodes(bijection)
      self.dup.map_nodes!(bijection)
    end
  
    private

    # The main recursive bijection algorithm.
    #
    # This algorithm is very similar to the one explained by Jeremy Carroll in
    # http://www.hpl.hp.com/techreports/2001/HPL-2001-293.pdf. Page 12 has the
    # relevant pseudocode.
    #
    # Many more comments are in the method itself.
    #
    # @param [RDF::Query::Solutions]  anon_solns
    # @param [Array]            nodes
    # @param [RDF::Query::Solutions]  other_anon_solns
    # @param [Array]            other_nodes
    # @param [Hash]             these_grounded_hashes
    # @param [Hash]             other_grounded_hashes
    # @param [Hash]             options
    # @return [nil,Hash]
    # @private
    def build_bijection_to(anon_solns, nodes, other_anon_solns, other_nodes, these_grounded_hashes = {}, other_grounded_hashes = {}, opts = {})

      # Create a hash signature of every node, based on the signature of
      # solutions it exists in.  
      # We also save hashes of nodes that cannot be reliably known; we will use
      # that information to eliminate possible recursion combinations.
      # 
      # Any mappings given in the method parameters are considered grounded.
      these_hashes, these_ungrounded_hashes = RDF::Query::Solutions.hash_nodes(anon_solns, nodes, these_grounded_hashes, opts[:canonicalize])
      other_hashes, other_ungrounded_hashes = RDF::Query::Solutions.hash_nodes(other_anon_solns, other_nodes, other_grounded_hashes, opts[:canonicalize])

      # Grounded hashes are built at the same rate between the two graphs (if
      # they are isomorphic).  If there exists a grounded node in one that is
      # not in the other, we can just return.  Ungrounded nodes might still
      # conflict, so we don't check them.  This is a little bit messy in the
      # middle of the method, and probably slows down isomorphic checks,  but
      # prevents almost-isomorphic cases from getting nutty.
      return nil if these_hashes.values.any? { |hash| !(other_hashes.values.member?(hash)) }
      return nil if other_hashes.values.any? { |hash| !(these_hashes.values.member?(hash)) }

      # Using the created hashes, map nodes to other_nodes
      # Ungrounded hashes will also be equal, but we keep the distinction
      # around for when we recurse later (we only recurse on ungrounded nodes)
      bijection = {}
      nodes.each do | node |
        other_node, other_hash = other_ungrounded_hashes.find do | other_node, other_hash |
          # we need to use eql?, as coincedentally-named bnode identifiers are == in rdf.rb
          these_ungrounded_hashes[node].eql? other_hash
        end
        next unless other_node
        bijection[node] = other_node

        # Deletion is required to keep counts even; two nodes with identical
        # signatures can biject to each other at random.
        other_ungrounded_hashes.delete other_node
      end

      # bijection is now a mapping of nodes to other_nodes.  If all are
      # accounted for on both sides, we have a bijection.
      #
      # If not, we will speculatively mark pairs with matching ungrounded
      # hashes as bijected and recurse.
      unless (bijection.keys.sort == nodes.sort) && (bijection.values.sort == other_nodes.sort)
        bijection = nil
        nodes.any? do | node |

          # We don't replace grounded nodes' hashes
          next if these_hashes.member? node
          other_nodes.any? do | other_node |

            # We don't replace grounded other_nodes' hashes
            next if other_hashes.member? other_node

            # The ungrounded signature must match for this to potentially work
            next unless these_ungrounded_hashes[node] == other_ungrounded_hashes[other_node]

            hash = Digest::SHA1.hexdigest(node.to_s)
            bijection = build_bijection_to(anon_solns, nodes, other_anon_solns, other_nodes, these_hashes.merge( node => hash), other_hashes.merge(other_node => hash))
          end
          bijection
        end
      end

      bijection
    end

    # Blank nodes appearing in given list of solutions
    # @private
    # @return [Array<RDF::Node>]
    def self.blank_nodes_in(blank_soln_list)
      blank_soln_list.map(&:blank_nodes).flatten.uniq
    end

    # Given a set of solutions, create a mapping of node => SHA1 for a given
    # set of blank nodes.  grounded_hashes is a mapping of node => SHA1 pairs
    # that we will take as a given, and use those to make more specific
    # signatures of other nodes.  
    #
    # Returns a tuple of hashes:  one of grounded hashes, and one of all
    # hashes.  grounded hashes are based on non-blank nodes and grounded blank
    # nodes, and can be used to determine if a node's signature matches
    # another.
    #
    # @param [Array] solutions 
    # @param [Array] nodes
    # @param [Hash] grounded_hashes
    # @private
    # @return [Hash, Hash]
    def self.hash_nodes(solutions, nodes, grounded_hashes, canonicalize = false)
      hashes = grounded_hashes.dup
      ungrounded_hashes = {}
      hash_needed = true

      # We may have to go over the list multiple times.  If a node is marked as
      # grounded, other nodes can then use it to decide their own state of
      # grounded.
      while hash_needed 
        starting_grounded_nodes = hashes.size
        nodes.each do | node |
          unless hashes.member? node
            grounded, hash = node_hash_for(node, solutions, hashes, canonicalize)
            if grounded
              hashes[node] = hash
            end
            ungrounded_hashes[node] = hash
          end
        end
        # after going over the list, any nodes with a unique hash can be marked
        # as grounded, even if we have not tied them back to a root yet.
        uniques = {}
        ungrounded_hashes.each do |node, hash|
          uniques[hash] = uniques[hash].is_a?(RDF::Node) ? false : node
        end
        uniques.each do |hash, node|
          hashes[node] = hash unless node == false
        end
        hash_needed = starting_grounded_nodes != hashes.size
      end
      [hashes,ungrounded_hashes]
    end

    # Generate a hash for a node based on the signature of the solutions it
    # appears in.  Signatures consist of grounded elements in solutions
    # associated with a node, that is, anything but an ungrounded anonymous
    # node.  Creating the hash is simply hashing a sorted list of each
    # solution's signature, which is itself a concatenation of the string form
    # of all grounded elements.
    #
    # Nodes other than the given node are considered grounded if they are a
    # member in the given hash.
    #
    # Returns a tuple consisting of grounded being true or false and the String
    # for the hash
    # @private
    # @return [Boolean, String]
    def self.node_hash_for(node, solutions, hashes, canonicalize)
      solution_signatures = []
      grounded = true
      solutions.each do | solution |
        # include? uses ==, which matches to agressively for Nodes
        if solution.bindings.values.any? {|v| v.eql?(node)}
          solution_signatures << hash_string_for(solution, hashes, node, canonicalize)
          solution.bindings.values.each do | resource |
            grounded = false unless grounded(resource, hashes) || resource == node
          end
        end
      end
      # Note that we sort the signatures--without a canonical ordering, 
      # we might get different hashes for equivalent nodes.
      [grounded,Digest::SHA1.hexdigest(solution_signatures.sort.to_s)]
    end

    # Provide a string signature for the given solution, collecting
    # string signatures for grounded node elements.
    # return [String]
    # @private
    def self.hash_string_for(solution, hashes, node, canonicalize)
      solution.bindings.keys.sort.map {|k| k.to_s + string_for_node(solution[k], hashes, node, canonicalize)}.join("")
    end

    # Returns true if a given node is grounded
    # A node is groundd if it is not a blank node or it is included
    # in the given mapping of grounded nodes.
    # @return [Boolean]
    # @private
    def self.grounded(node, hashes)
      (!(node.node?)) || (hashes.member? node)
    end

    # Provides a string for the given node for use in a string signature
    # Non-anonymous nodes will return their string form.  Grounded anonymous
    # nodes will return their hashed form.
    # @return [String]
    # @private
    def self.string_for_node(node, hashes, target, canonicalize)
      case
        when node == target
          "itself"
        when node.node? && hashes.member?(node)
          hashes[node]
        when node.node?
          "a blank node"
        # RDF.rb auto-boxing magic makes some literals the same when they
        # should not be; the ntriples serializer will take care of us
        when node.literal?
          node.class.name + RDF::NTriples.serialize(canonicalize ? node.canonicalize : node)
        else
          node.to_s
      end
    end
  end

  # Mixin for RDF::Query::Solution
  class Solution
    # Does solution use any blank nodes?
    # @return [Boolean]
    def has_blank_nodes?
      !blank_nodes.empty?
    end

    # Blank nodes within a solution
    # @return [Array<RDF::Node>]
    def blank_nodes
      bindings.values.select {|v| v.is_a?(RDF::Node)}.uniq
    end
  end
end
