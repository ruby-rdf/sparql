source "https://rubygems.org"

gemspec :name => ""

gem "rdf",            :git => "git://github.com/ruby-rdf/rdf.git"
gem "rdf-xsd",        :git => "git://github.com/ruby-rdf/rdf-xsd.git"
gem 'ebnf',           :git => "git://github.com/gkellogg/ebnf.git"
gem 'rdf-aggregate-repo', :git => "git://github.com/ruby-rdf/rdf-aggregate-repo.git"
#gem 'sparql-client',  :git => "git://github.com/ruby-rdf/sparql-client.get"
gem 'sparql-client', :path => '../sparql-client'

group :development do
  gem "rdf-spec",     :git => "git://github.com/ruby-rdf/rdf-spec.git"
  gem "rdf-turtle",   :git => "git://github.com/ruby-rdf/rdf-turtle.git"
  gem "rdf-trig",     :git => "git://github.com/ruby-rdf/rdf-trig.git"
  gem "equivalent-xml", '>= 0.2.8'
end

group :debug do
  gem 'shotgun'  unless ENV['CI']
  gem 'debugger', :platforms => [:mri_19, :mri_20]
  gem "wirble"
  gem 'redcarpet', :platforms => :ruby
end

group :test do
  gem 'rake'
end
