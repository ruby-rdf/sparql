Gem::Specification.new do |s|
  s.name = "sparql"
  s.version = "0.0.1"
  s.date = "2008-07-15"
  s.summary = "SPARQL library for Ruby."
  s.email = "pius+github@uyiosa.com"
  s.homepage = "http://github.com/pius/sparql"
  s.description = "sparql is a Ruby library for parsing SPARQL queries.  Implements the formal grammar of SPARQL as a parsing expression grammar."
  s.has_rdoc = true
  s.authors = ['Pius Uzamere']
  s.files = ["README.markdown", "Rakefile", "sparql.gemspec", "lib/sparql.rb", "lib/sparql/execute_sparql.rb", "lib/sparql/sparql.treetop", "coverage/index.html", "coverage/lib-sparql-execute_sparql_rb.html", "coverage/lib-sparql_rb.html"]
  s.test_files = ["spec/spec.opts", "spec/fixtures", "spec/spec_helper.rb", "spec/unit/check_parsing_spec.rb"]
  #s.rdoc_options = ["--main", "README.txt"]
  #s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.add_dependency("treetop", [">= 1.2.4"])
end