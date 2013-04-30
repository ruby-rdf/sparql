begin
  require 'sxp' # @see http://rubygems.org/gems/sxp
rescue LoadError
  abort "SPARQL::Algebra specs require the SXP gem (hint: `gem install sxp')."
end

def sse_examples(filename)
  input = File.read(File.join(File.dirname(__FILE__), filename))
  input.gsub!(/\s\-INF/, " \"-INF\"^^<#{RDF::XSD.double}>") # Shorthand
  input.gsub!(/\s\+INF/, " \"INF\"^^<#{RDF::XSD.double}>")  # Shorthand
  input.gsub!(/\sNaN/,  " \"NaN\"^^<#{RDF::XSD.double}>")   # Shorthand
  datatypes = {
    'rdf:langString' => RDF.langString,
    'xsd:double'     => RDF::XSD.double,
    'xsd:float'      => RDF::XSD.float,
    'xsd:integer'    => RDF::XSD.integer,
    'xsd:int'        => RDF::XSD.int,
    'xsd:decimal'    => RDF::XSD.decimal,
    'xsd:string'     => RDF::XSD.string,
    'xsd:token'      => RDF::XSD.token,
    'xsd:boolean'    => RDF::XSD.boolean,
    'xsd:dateTime'   => RDF::XSD.dateTime,
  }
  datatypes.each { |qname, uri| input.gsub!(qname, "<#{uri}>") } # Shorthand
  examples = SXP::Reader::SPARQL.read_all(input)
  examples.inject({}) do |result, (tag, input, output)|
    output = case output
      when :TypeError         then TypeError
      when :ZeroDivisionError then ZeroDivisionError
      else output
    end
    result.merge(input => output)
  end
end

def verify(examples)
  examples.each do |input, output|
    describe ".evaluate(#{input.to_sse})" do
      if output.is_a?(Class)
        it "raises #{output.inspect}" do
          lambda { @op.evaluate(*input[1..-1]) }.should raise_error(output)
        end
      else
        it "returns #{repr(output)}" do
          result = @op.evaluate(*input[1..-1])
          if output.is_a?(RDF::Literal::Double) && output.nan?
            result.should be_nan
          else
            result.should == output
          end
        end
      end
    end
  end
end
