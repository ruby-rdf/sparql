source "https://rubygems.org"

gemspec

group :development do
  gem "equivalent-xml", '>= 0.2.8'
  gem 'psych', platforms: [:mri, :rbx]
  gem 'simplecov',      require: false
  gem 'coveralls',      require: false
end

group :debug do
  gem 'shotgun'  unless ENV['CI']
  gem 'pry'
  gem 'pry-byebug', platforms: :mri
  gem "wirble"
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
