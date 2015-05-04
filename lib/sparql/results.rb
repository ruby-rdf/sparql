module SPARQL
  # Generate SPARQL Results as Boolean, XML or JSON
  #
  # This module is a mixin for RDF::Query::Solutions
  module Results
    MIME_TYPES = {
      json: 'application/sparql-results+json',
      html: 'text/html',
      :xml  => 'application/sparql-results+xml',
      csv: 'text/csv',
      tsv: 'text/tab-separated-values'
    }
    
    ##
    # Generate Solutions as JSON
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/
    def to_json
      require 'json' unless defined?(::JSON)
      
      bindings = self.map do |solution|
        variable_names.inject({}) do |memo, n|
          memo.merge case s = solution[n]
          when RDF::URI
            {n => {type: "uri", value: s.to_s }}
          when RDF::Node
            {n => {type: "bnode", value: s.id }}
          when RDF::Literal
            if s.datatype?
              {n => {type: "typed-literal", datatype: s.datatype.to_s, value: s.to_s }}
            elsif s.language
              {n => {type: "literal", "xml:lang" => s.language.to_s, value: s.to_s }}
            else
              {n => {type: "literal", value: s.to_s }}
            end
          else
            {}
          end
        end
      end

      {
        :head     => { vars: variable_names },
        :results  => { bindings: bindings}
      }.to_json
    end
    
    ##
    # Generate Solutions as XML
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-XMLres/
    def to_xml
      require 'builder' unless defined?(::Builder)
      
      xml = ::Builder::XmlMarkup.new(indent: 2)
      xml.instruct!
      xml.sparql(xmlns: "http://www.w3.org/2005/sparql-results#") do
        xml.head do
          variable_names.each do |n|
            xml.variable(name: n)
          end
        end
        xml.results do
          self.each do |solution|
            xml.result do
              variable_names.each do |n|
                s = solution[n]
                next unless s
                xml.binding(name: n) do
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
      
      xml = ::Builder::XmlMarkup.new(indent: 2)
      xml.table(class: "sparql") do
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

    ##
    # Generate Solutions as CSV
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#results
    def to_csv
      require 'csv' unless defined?(::CSV)
      bnode_map = {}
      bnode_gen = "_:a"
      CSV.generate(row_sep: "\r\n") do |csv|
        csv << variable_names.to_a
        self.each do |solution|
          csv << variable_names.map do |n|
            case term = solution[n]
            when RDF::Node then bnode_map[term] ||=
              begin
                this = bnode_gen
                bnode_gen = bnode_gen.succ
                this
              end
            else
              solution[n].to_s
            end
          end
        end
      end
    end
    ##
    # Generate Solutions as TSV
    # @return [String]
    # @see http://www.w3.org/TR/rdf-sparql-json-res/#results
    def to_tsv
      require 'csv' unless defined?(::CSV)
      bnode_map = {}
      bnode_gen = "_:a"
      results = [
        variable_names.map {|v| "?#{v}"}.join("\t")
      ] + self.map do |solution|
        variable_names.map do |n|
          case term = solution[n]
          when RDF::Literal::Integer, RDF::Literal::Decimal, RDF::Literal::Double
            term.canonicalize.to_s
          when nil
            ""
          else
            RDF::NTriples.serialize(term)
          end
        end.join("\t")
      end
      results.join("\n") + "\n"
    end
  end
  
  ##
  # Serialize solutions using the determined format
  #
  # @param [RDF::Query::Solutions, RDF::Queryable, Boolean] solutions
  #   Solutions as either a solution set, a Queryable object (such as a graph) or a Boolean value
  # @param [Hash{Symbol => Object}] options
  # @option options [#to_sym] :format
  #   Format of results, one of :html, :json or :xml.
  #   May also be an RDF::Writer format to serialize DESCRIBE or CONSTRUCT results
  # @option options [String] :content_type
  #   Format of results, one of 'application/sparql-results+json' or 'application/sparql-results+xml'
  #   May also be an RDF::Writer content_type to serialize DESCRIBE or CONSTRUCT results
  # @option options [Array<String>] :content_types
  #   Similar to :content_type, but takes an ordered array of appropriate content types,
  #   and serializes using the first appropriate type, including wild-cards.
  # @return [String]
  #   String with serialized results and `#content_type`
  # @raise [RDF::WriterError] when inappropriate formatting options are used
  def serialize_results(solutions, options = {})
    format = options[:format].to_sym if options[:format]
    content_type = options[:content_type].to_s.split(';').first
    content_types = Array(options[:content_types] || '*/*')

    if !format && !content_type
      case solutions
      when RDF::Queryable
        content_type = first_content_type(content_types, RDF::Format.content_types.keys) || 'text/plain'
        format = RDF::Writer.for(content_type: content_type).to_sym
      else
        content_type = first_content_type(content_types, SPARQL::Results::MIME_TYPES.values) || 'application/sparql-results+xml'
        format = SPARQL::Results::MIME_TYPES.invert[content_type]
      end
    end

    serialization = case solutions
    when TrueClass, FalseClass, RDF::Literal::TRUE, RDF::Literal::FALSE
      solutions = solutions.object if solutions.is_a?(RDF::Literal)
      case format
      when :json
        require 'json' unless defined?(::JSON)
        {boolean: solutions}.to_json
      when :xml
        require 'builder' unless defined?(::Builder)
        xml = ::Builder::XmlMarkup.new(indent: 2)
        xml.instruct!
        xml.sparql(xmlns: "http://www.w3.org/2005/sparql-results#") do
          xml.boolean(solutions.to_s)
        end
      when :html
        require 'builder' unless defined?(::Builder)
        content_type = "text/html"
        xml = ::Builder::XmlMarkup.new(indent: 2)
        xml.div(solutions.to_s, class: "sparql")
      else
        raise RDF::WriterError, "Unknown format #{(format || content_type).inspect} for #{solutions.class}"
      end
    when RDF::Queryable
      begin
        require 'linkeddata'
      rescue LoadError => e
        require 'rdf/ntriples'
      end
      fmt = RDF::Format.for(format ? format.to_sym : {content_type: content_type})
      unless fmt
        fmt = RDF::Format.for(file_extension: format.to_sym) || RDF::NTriples::Format
        format = fmt.to_sym
      end
      format ||= fmt.to_sym
      content_type ||= fmt.content_type.first
      results = solutions.dump(format, options)
      raise RDF::WriterError, "Unknown format #{fmt.inspect} for #{solutions.class}" unless results
      results
    when RDF::Query::Solutions
      case format
      when :json  then solutions.to_json
      when :xml   then solutions.to_xml
      when :html  then solutions.to_html
      when :csv   then solutions.to_csv
      when :tsv   then solutions.to_tsv
      else
        raise RDF::WriterError, "Unknown format #{(format || content_type).inspect} for #{solutions.class}"
      end
    end

    content_type ||= SPARQL::Results::MIME_TYPES[format] if format
    
    serialization.instance_eval do
      define_singleton_method(:content_type) { content_type }
    end
    
    serialization
  end
  module_function :serialize_results

  ERROR_MESSAGE = %q(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
  <head>
    <title>SPARQL Processing Service: %s</title>
  </head>
  <body>
    <p>%s: %s</p>
  </body>
</html>
).freeze
  
  ##
  # Find a content_type from a list using an ordered list of acceptable content types
  # using wildcard matching
  #
  # @param [Array<String>] acceptable
  # @param [Array<String>] available
  # @return [String]
  #
  # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
  def first_content_type(acceptable, available)
    return acceptable.first if available.empty?
    available.flatten!
    acceptable.each do |pattern|
      type = available.detect { |t| File.fnmatch(pattern, t) }
      return type if type
    end
    nil
  end
  module_function :first_content_type

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
    content_type ||= SPARQL::Results::MIME_TYPES[format]
    serialization = case content_type
    when 'text/html'
      title = exception.respond_to?(:title) ? exception.title : exception.class.to_s
      ERROR_MESSAGE % [title, title, exception.message]
    else
      content_type = "text/plain"
      exception.message
    end
    
    serialization.instance_eval do
      define_singleton_method(:content_type) { content_type }
    end

    serialization
  end
  module_function :serialize_exception
end
