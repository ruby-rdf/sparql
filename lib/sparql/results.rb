module SPARQL
  # Generate SPARQL Results as Boolean, XML or JSON
  #
  # This module is a mixin for RDF::Query::Solutions
  module Results
    MIME_TYPES = {
      :json => 'application/sparql-results+json',
      :html => 'text/html',
      :xml  => 'application/sparql-results+xml',
    }
    
    ##
    # Generate Solutions as JSON
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/
    def to_json
      require 'json' unless defined?(::JSON)
      
      bindings = self.map do |solution|
        variable_names.map do |n|
          case s = solution[n]
          when RDF::URI
            {n => {:type => "uri", :value => s.to_s }}
          when RDF::Node
            {n => {:type => "bnode", :value => s.id }}
          when RDF::Literal
            if s.datatype?
              {n => {:type => "literal", :datatype => s.datatype.to_s, :value => s.to_s }}
            elsif s.language
              {n => {:type => "literal", "xml:lang" => s.language.to_s, :value => s.to_s }}
            else
              {n => {:type => "literal", :value => s.to_s }}
            end
          end
        end.compact
      end.flatten

      {
        :head     => { :vars => variable_names },
        :results  => { :bindings => bindings}
      }.to_json
    end
    
    ##
    # Generate Solutions as XML
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-XMLres/
    def to_xml
      require 'builder' unless defined?(::Builder)
      
      xml = ::Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.sparql(:xmlns => "http://www.w3.org/2005/sparql-results#") do
        xml.head do
          variable_names.each do |n|
            xml.variable(:name => n)
          end
        end
        xml.results do
          self.each do |solution|
            xml.result do
              variable_names.each do |n|
                s = solution[n]
                next unless s
                xml.binding(:name => n) do
                  case s
                  when RDF::URI
                    xml.uri(s.to_s)
                  when RDF::Node
                    xml.bnode(s.id)
                  when RDF::Literal
                    if s.datatype?
                      xml.literal(s.to_s, "datatype" => s.datatype.to_s)
                    elsif s.language
                      xml.literal(s.to_s, "xml:lang" => s.language.to_s)
                    else
                      xml.literal(s.to_s)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    
    ##
    # Generate Solutions as HTML
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-XMLres/
    def to_html
      require 'builder' unless defined?(::Builder)
      
      xml = ::Builder::XmlMarkup.new(:indent => 2)
      xml.table(:class => "sparql") do
        xml.tbody do
          xml.tr do
            variable_names.each do |n|
              xml.th(n.to_s)
            end
          end
          self.each do |solution|
            xml.tr do
              variable_names.each do |n|
                xml.td(RDF::NTriples.serialize(solution[n]))
              end
            end
          end
        end
      end
    end
  end
  
  ##
  # Serialize solutions using the determined format
  #
  # @param [RDF::Query::Solutions, RDF::Queryable, Boolean] solutions
  #   Solutions as either a solution set, a Queryable object (such as a graph) or a Boolean value
  # @param [Hash{Symbol => Object}] options
  # @option options [:format]
  #   Format of results, one of :html, :json or :xml.
  #   May also be an RDF::Writer format to serialize DESCRIBE or CONSTRUCT results
  # @option options [:content_type]
  #   Format of results, one of 'application/sparql-results+json' or 'application/sparql-results+xml'
  #   May also be an RDF::Writer content_type to serialize DESCRIBE or CONSTRUCT results
  # @return [String]
  #   String with serialized results and #content_type
  def serialize_results(solutions, options = {})
    format = options[:format]
    content_type = options[:content_type]
    format ||= RDF::Query::Solutions::MIME_TYPES.invert[content_type] if content_type

    serialization = case solutions
    when TrueClass, FalseClass
      case format ||= :xml
      when :json
        require 'json' unless defined?(::JSON)
        {:boolean => solutions}.to_json
      when :xml
        require 'builder' unless defined?(::Builder)
        xml = ::Builder::XmlMarkup.new(:indent => 2)
        xml.instruct!
        xml.sparql(:xmlns => "http://www.w3.org/2005/sparql-results#") do
          xml.boolean(solutions.to_s)
        end
      when :html
        require 'builder' unless defined?(::Builder)
        xml = ::Builder::XmlMarkup.new(:indent => 2)
        xml.div(solutions.to_s, :class => "sparql")
      end
    when RDF::Queryable
      format ||= :ntriples
      fmt = RDF::Format.for(format.to_sym)
      content_type ||= fmt.content_types.first
      fmt.writer.buffer << solutions
    when RDF::Query::Solutions
      case format ||= :xml
      when :json  then solutions.to_json
      when :xml   then solutions.to_xml
      when :html  then solutions.to_html
      end
    end

    content_type ||= RDF::Query::Solutions::MIME_TYPES[format] if format
    
    def serialization.content_type; content_type; end
    
    serialization
  end
  module_function :serialize_results

  ERROR_MESSAGE = %q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <title>SPARQL Processing Service: %s</title>
  </head>
  <body>
    <p> %s: %s</p>
  </body>
</html>
).freeze
  
  ##
  # Serialize error results
  #
  # Returns appropriate content based upon an execution exception
  # @param [Exception] exception
  # @param [Hash{Symbol => Object}] options
  # @option options [:format]
  #   Format of results, one of :html, :json or :xml.
  #   May also be an RDF::Writer format to serialize DESCRIBE or CONSTRUCT results
  # @option options [:content_type]
  #   Format of results, one of 'application/sparql-results+json' or 'application/sparql-results+xml'
  #   May also be an RDF::Writer content_type to serialize DESCRIBE or CONSTRUCT results
  # @return [String]
  #   String with serialized results and #content_type
  def serialize_exception(exception, options = {})
    format = options[:format]
    content_type = options[:content_type]
    content_type ||= RDF::Query::Solutions::MIME_TYPES[format]
    serialization = case content_type
    when :html
      ERROR_MESSAGE % [e.title, t.title, e.message]
    else
      content_type = "text/plain"
      e.message
    end
    
    def serialization.content_type; content_type; end

    serialization
  end
  module_function :serialize_exception
end
