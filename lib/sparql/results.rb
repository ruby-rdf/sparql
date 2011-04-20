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
    
    # Generate Solutions as JSON
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/
    def to_json
    end
    
    # Generate Solutions as XML
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-XMLres/
    def to_xml
      require 'builder'
      
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct!
      xml.sparql(:xmlns => "http://www.w3.org/2005/sparql-results#") do
        unless variable_names.empty?
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
                    case 
                    when RDF::URI
                      xml.uri(s.to_s)
                    when RDF::Node
                      xml.bnode(s.to_s)
                    when RDF::Literal]
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
    end
    
    # Generate Solutions as HTML
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-XMLres/
    def to_html
      require 'builder'
      
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.table(:class => "sparql") do
        xml.tbody do
          unless variable_names.empty?
            xml.tr do
              variable_names.each do |n|
                xml.th(n)
              end
            end
            self.each do |solution|
              xml.tr do
                variable_names.each do |n|
                  xml.td(solution[n].to_s)
                end
              end
            end
          end
        end
      end
    end
  end
  
  # Serialize solutions using the determined format
  #
  # @param [RDF::Query::Solutions, RDF::Queryable, Boolean] solutions
  #   Solutions as either a solution set, a Queryable object (such as a graph) or a Boolean value
  # @param [Hash<Symbol => Object>] options
  # @option options [:format]
  #   Format of results, one of :html, :json or :xml.
  #   May also be an RDF::Writer format to serialize DESCRIBE or CONSTRUCT results
  # @option options [:content_type]
  #   Format of results, one of 'application/sparql-results+json' or 'application/sparql-results+xml'
  #   May also be an RDF::Writer content_type to serialize DESCRIBE or CONSTRUCT results
  def serialize_results(solutions, options)
    format = options[:format]
    format ||= RDF::Query::Solutions::MIME_TYPES.invert[options[:content_type]]
    case solutions
    when Boolean
      case format
      when :json
      when :xml
        require 'builder'
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.instruct!
        xml.sparql(:xmlns => "http://www.w3.org/2005/sparql-results#") do
          xml.boolean(solutions.to_s)
        end
      when :html
        xml = Builder::XmlMarkup.new(:indent => 2)
        xml.div(solutions.to_s, :class => "sparql")
      end
    when RDF::Queryable
      writer = RDF::Writer.for(format.to_sym)
      writer ||= RDF::NTriples::Writer
      writer.buffer << solutions
    when RDF::Query::Solutions
      case format
      when :json  then solutions.to_json
      when :xml   then solutions.to_xml
      when :html  then solutions.to_html
      end
    end
  end
end