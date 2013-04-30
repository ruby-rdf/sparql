source "https://rubygems.org"

gemspec :name => ""

gem "rdf",            :git => "git://github.com/ruby-rdf/rdf.git"
gem "rdf-spec",       :git => "git://github.com/ruby-rdf/rdf-spec.git"
gem "rdf-xsd",        :git => "git://github.com/ruby-rdf/rdf-xsd.git"
gem "rdf-turtle",     :git => "git://github.com/ruby-rdf/rdf-turtle.git"
gem 'ebnf',           :git => "git://github.com/gkellogg/ebnf.git"
gem 'rdf-aggregate-repo', :git => "git://github.com/ruby-rdf/rdf-aggregate-repo.git"

group :debug do
  gem 'shotgun'  unless ENV['CI']
  gem 'debugger', :platforms => :mri_19
  gem "wirble"
  gem 'redcarpet', :platforms => :ruby
end

group :test do
  gem 'rake'
end
