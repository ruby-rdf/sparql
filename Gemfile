source 'http://rubygems.org'

# Include non-released gems first
gem 'rdf',              :git => "https://github.com/gkellogg/rdf.git", :branch => "type-check-mixin"
gem 'rdf-n3',           :git => "https://github.com/gkellogg/rdf-n3.git", :require => "rdf/n3"
gem 'rdf-rdfa',         :git => "https://github.com/gkellogg/rdf-rdfa.git", :require => "rdf/rdfa"
gem 'rdf-rdfxml',       :git => "https://github.com/gkellogg/rdf-rdfxml.git", :require => "rdf/rdfxml"
gem 'rdf-json',         :git => "https://github.com/gkellogg/rdf-json.git", :branch => "0.4.x", :require => 'rdf/json'
gem 'rdf-trix',         :git => "https://github.com/gkellogg/rdf-trix.git", :branch => "0.4.x", :require => 'rdf/trix'
gem 'linkeddata',       :git => "https://github.com/gkellogg/linkeddata.git", :branch => "0.4.x", :require => "rdf/rdfxml"
gem 'sparql-client',    :git => "https://github.com/gkellogg/sparql-client.git", :branch => "0.4.x", :require => 'sparql/client'
gem 'sparql-algebra',   :git => "https://github.com/gkellogg/sparql-algebra.git", :require => 'sparql/algebra'
gem 'sparql-grammar',   :git => "https://github.com/gkellogg/sparql-grammar.git", :require => 'sparql/grammar'

gem 'addressable',      '2.2.4'
gem 'sxp',              '>= 0.0.5'
gem 'builder',          '>= 3.0.0'
gem 'json',             '>= 1.5.1'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'rspec'
  gem 'nokogiri'
  gem 'open-uri-cached'
end
