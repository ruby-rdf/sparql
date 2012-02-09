require 'rack'
begin
  require 'linkeddata'
rescue LoadError => e
  require 'rdf/ntriples'
end
require 'sparql'

module Rack
  module SPARQL
    autoload :ContentNegotiation, 'rack/sparql/conneg'

    ##
    # Registers all known RDF formats with Rack's MIME types registry.
    #
    # Registers both known file extensions and format symbols.
    #
    # @param  [Hash{Symbol => Object}] options
    # @option options [Boolean]        :overwrite (false)
    # @return [void]
    def self.register_mime_types!(options = {})
      if defined?(Rack::Mime::MIME_TYPES)
        RDF::Format.each do |format|
          if !Rack::Mime::MIME_TYPES.has_key?(file_ext = ".#{format.to_sym}") || options[:overwrite]
            Rack::Mime::MIME_TYPES.merge!(file_ext => format.content_type.first)
          end
        end
        RDF::Format.file_extensions.each do |file_ext, formats|
          if !Rack::Mime::MIME_TYPES.has_key?(file_ext = ".#{file_ext}") || options[:overwrite]
            Rack::Mime::MIME_TYPES.merge!(file_ext => formats.first.content_type.first)
          end
        end
      end
    end
  end
end

Rack::SPARQL.register_mime_types!
