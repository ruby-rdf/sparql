##
# Extensions for Ruby's `NilClass` class.
class NilClass
  ##
  # Returns the SXP representation of this object.
  #
  # @return [String]
  def to_sxp
    RDF.nil.to_s
  end
end

##
# Extensions for Ruby's `FalseClass` class.
class FalseClass
  ##
  # Returns the SXP representation of this object.
  #
  # @return [String]
  def to_sxp
    'false'
  end
end

##
# Extensions for Ruby's `TrueClass` class.
class TrueClass
  ##
  # Returns the SXP representation of this object.
  #
  # @return [String]
  def to_sxp
    'true'
  end
end
