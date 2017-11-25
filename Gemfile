source "https://rubygems.org"

gemspec

gem 'ebnf',               github: "gkellogg/ebnf",                branch: "develop"
gem 'rdf',                github: "ruby-rdf/rdf",                 branch: "develop"
gem 'rdf-aggregate-repo', github: "ruby-rdf/rdf-aggregate-repo",  branch: "develop"
gem "rdf-xsd",            github: "ruby-rdf/rdf-xsd",             branch: "develop"
gem 'sparql-client',      github: "ruby-rdf/sparql-client",       branch: "develop"
gem 'sxp',                github: "dryruby/sxp.rb",               branch: "develop"

group :development do
  gem 'json-ld',          github: "ruby-rdf/json-ld",             branch: "develop"
  gem 'linkeddata',       github: "ruby-rdf/linkeddata",          branch: "develop"
  gem 'rdf-isomorphic',   github: "ruby-rdf/rdf-isomorphic",      branch: "develop"
  gem 'rdf-json',         github: "ruby-rdf/rdf-json",            branch: "develop"
  gem 'rdf-microdata',    github: "ruby-rdf/rdf-microdata",       branch: "develop"
  gem 'rdf-n3',           github: "ruby-rdf/rdf-n3",              branch: "develop"
  gem 'rdf-rdfa',         github: "ruby-rdf/rdf-rdfa",            branch: "develop"
  gem 'rdf-reasoner',     github: "ruby-rdf/rdf-reasoner",        branch: "develop"
  gem 'rdf-rdfxml',       github: "ruby-rdf/rdf-rdfxml",          branch: "develop"
  gem "rdf-spec",         github: "ruby-rdf/rdf-spec",            branch: "develop"
  gem 'rdf-tabular',      github: "ruby-rdf/rdf-tabular",         branch: "develop"
  gem 'rdf-trig',         github: "ruby-rdf/rdf-trig",            branch: "develop"
  gem 'rdf-trix',         github: "ruby-rdf/rdf-trix",            branch: "develop"
  gem 'rdf-turtle',       github: "ruby-rdf/rdf-turtle",          branch: "develop"
  gem 'rdf-vocab',        github: "ruby-rdf/rdf-vocab",           branch: "develop"
  gem 'ld-patch',         github: "gkellogg/ld-patch",            branch: "develop"
  gem "equivalent-xml",   '>= 0.6.0'
  gem 'psych',            platforms: [:mri, :rbx]
  gem 'simplecov',        require: false
  gem 'coveralls',        require: false
end

group :debug do
  gem 'shotgun'  unless ENV['CI']
  gem 'pry'
  gem 'pry-byebug', platforms: :mri
  gem 'redcarpet', platforms: :ruby
  gem 'ruby-prof', platforms: :mri
end

group :test do
  gem 'rake'
end

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'rubinius', '~> 2.0'
end
