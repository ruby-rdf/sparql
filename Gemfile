source "https://rubygems.org"

gemspec :name => ""

gem "rdf",            :git => "git://github.com/ruby-rdf/rdf.git", :branch => "develop"
gem "rdf-xsd",        :git => "git://github.com/ruby-rdf/rdf-xsd.git", :branch => "develop"
gem 'ebnf',           :git => "git://github.com/gkellogg/ebnf.git"
gem 'rdf-aggregate-repo', :git => "git://github.com/ruby-rdf/rdf-aggregate-repo.git", :branch => "develop"
gem 'sparql-client',  :git => "git://github.com/ruby-rdf/sparql-client.git", :branch => "develop"
gem 'sxp',            :git => "git://github.com/gkellogg/sxp-ruby.git"

group :development do
  gem "linkeddata",     :git => "git://github.com/ruby-rdf/linkeddata.git", :branch => "develop"
  gem 'rdf-isomorphic', :git => "git://github.com/ruby-rdf/rdf-isomorphic.git", :branch => "develop"
  gem 'rdf-json',       :git => "git://github.com/ruby-rdf/rdf-json.git", :branch => "develop"
  gem 'rdf-microdata',  :git => "git://github.com/ruby-rdf/rdf-microdata.git", :branch => "develop"
  gem 'rdf-n3',         :git => "git://github.com/ruby-rdf/rdf-n3.git", :branch => "develop"
  gem 'rdf-rdfa',       :git => "git://github.com/ruby-rdf/rdf-rdfa.git", :branch => "develop"
  gem 'rdf-rdfxml',     :git => "git://github.com/ruby-rdf/rdf-rdfxml.git", :branch => "develop"
  gem "rdf-spec",       :git => "git://github.com/ruby-rdf/rdf-spec.git", :branch => "develop"
  gem 'rdf-trig',       :git => "git://github.com/ruby-rdf/rdf-trig.git", :branch => "develop"
  gem 'rdf-trix',       :git => "git://github.com/ruby-rdf/rdf-trix.git", :branch => "develop"
  gem 'rdf-turtle',     :git => "git://github.com/ruby-rdf/rdf-turtle.git", :branch => "develop"
  gem 'json-ld',        :git => "git://github.com/ruby-rdf/json-ld.git", :branch => "develop"
  gem "equivalent-xml", '>= 0.2.8'
end

group :debug do
  gem 'shotgun'  unless ENV['CI']
  gem 'debugger', :platforms => :mri_19
  gem 'byebug', :platforms => :mri_20
  gem "wirble"
  gem 'redcarpet', :platforms => :ruby
  gem 'ruby-prof', :platforms => :mri
end

group :test do
  gem 'rake'
end
