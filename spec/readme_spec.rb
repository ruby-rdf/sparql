$:.unshift File.expand_path("..", __FILE__)
require 'spec_helper'
require 'linkeddata'
require 'strscan'

describe "README" do
  def self.read_examples
    examples = []
    readme = File.join(File.expand_path(File.dirname(__FILE__)), "..", "README.md")
    scanner = StringScanner.new(File.read(readme))
    scanner.skip_until(/^## Examples$/)
    until scanner.eos?
      break if scanner.matched =~ /## Adding SPARQL content negotiation/
      title = scanner.matched.match(/^### (.*)$/) && $1
      code = scanner.scan_until(/^##.*$/)
      code = code.match(/^(.*)^##.*$/m) && $1
      case title
      when "Command line processing"
        code.split("\n").reject {|c| c =~ /^\s*(?:#.*)?$/}.each do |command|
          examples << {title: command, sh: command}
        end
      else
        examples << {title: title, eval_true: code}
      end
    end
    examples
  end

  read_examples.each do |example|
    it "Example #{example[:title] || 'require'}" do
      if example[:eval_true]
        cmd = example[:eval_true].
          gsub('etc', File.join(File.dirname(__FILE__), '..', 'etc'))
        eval(cmd)
      elsif example[:sh] =~ /sparql server/m
        skip "running server"
      else
        cmd = example[:sh].
          sub('sparql', File.join(File.dirname(__FILE__), '..', 'bin', 'sparql')).
          sub('etc', File.join(File.dirname(__FILE__), '..', 'etc'))
        expect(IO.popen(cmd) {|io| io.read}).to be_truthy
      end
    end
  end

  context "Extension Functions" do
    let(:repo) {RDF::Repository.new << RDF::Statement.new(:s, RDF::URI("http://schema.org/email"), "gregg@greggkellogg.com")}
    let(:query) {%{
      PREFIX rsp: <http://rubygems.org/gems/sparql#>
      PREFIX schema: <http://schema.org/>
      SELECT ?crypted
      {
        [ schema:email ?email]
        BIND(rsp:crypt(?email) AS ?crypted)
      }
    }}
    before(:all) {SPARQL::Algebra::Expression.extensions.clear}

    it "returns encrypted string" do
      # Register a function using the IRI <http://rubygems.org/gems/sparql#crypt>
      crypt_iri = RDF::URI("http://rubygems.org/gems/sparql#crypt")
      SPARQL::Algebra::Expression.register_extension(crypt_iri) do |literal|
        raise TypeError, "argument must be a literal" unless literal.literal?
        RDF::Literal(literal.to_s.crypt("salt"))
      end

      results = SPARQL.execute(query, repo)
      expect(results).to describe_solutions([
        RDF::Query::Solution.new({crypted: RDF::Literal("gregg@greggkellogg.net".crypt("salt"))})
      ], nil)
    end
  end
end