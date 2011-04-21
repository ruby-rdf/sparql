require 'rdf'
require 'rdf/ntriples'
# override several inspect functions to improve output for what we're doing

class RDF::Literal
  def inspect
    RDF::NTriples::Writer.serialize(self) + " R:L:(#{self.class.to_s.match(/([^:]*)$/)})"
  end
end

class RDF::URI
  def inspect
    RDF::NTriples::Writer.serialize(self)
  end
end

class RDF::Node
  def inspect
    RDF::NTriples::Writer.serialize(self) + "(#{object_id})"
  end
end

class RDF::Graph
  def inspect
    "\n" + dump(:n3) + "\n"
  end
end

class RDF::Query
  def inspect
    "RDF::Query(#{context ? context.to_sxp : 'nil'})#{patterns.inspect}"
  end
end
