require File.join(File.dirname(__FILE__), 'spec_helper')
require 'linkeddata'
require 'strscan'

describe "README" do
  describe SPARQL do
  end
  
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
          examples << {:title => command, :sh => command}
        end
      else
        examples << {:title => title, :eval_true => code}
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
      else
        cmd = example[:sh].
          sub('sparql', File.join(File.dirname(__FILE__), '..', 'bin', 'sparql')).
          sub('etc', File.join(File.dirname(__FILE__), '..', 'etc'))
        IO.popen(cmd) {|io| io.read}.should be_true
      end
    end
  end
end