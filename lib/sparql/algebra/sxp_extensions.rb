##
# Extensions for Ruby's `NilClass` class.
class NilClass
  ##
  # Returns the SXP representation of this object.
  #
  # @param [Hash{Symbol => RDF::URI}] prefixes(nil)
  # @param [RDF::URI] base_uri(nil)
  # @return [String]
  def to_sxp(prefixes: nil, base_uri: nil)
    RDF.nil.to_s
  end
end

##
# Extensions for Ruby's `FalseClass` class.
class FalseClass
  ##
  # Returns the SXP representation of this object.
  #
  # @param [Hash{Symbol => RDF::URI}] prefixes(nil)
  # @param [RDF::URI] base_uri(nil)
  # @return [String]
  def to_sxp(prefixes: nil, base_uri: nil)
    'false'
  end
end

##
# Extensions for Ruby's `TrueClass` class.
class TrueClass
  ##
  # Returns the SXP representation of this object.
  #
  # @param [Hash{Symbol => RDF::URI}] prefixes(nil)
  # @param [RDF::URI] base_uri(nil)
  # @return [String]
  def to_sxp(prefixes: nil, base_uri: nil)
    'true'
  end
end
