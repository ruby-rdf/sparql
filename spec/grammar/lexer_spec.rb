# -*- encoding: utf-8 -*-
$:.unshift ".."
require 'spec_helper'
require 'ebnf'
require 'ebnf/ll1/lexer'

describe EBNF::LL1::Lexer do
  before(:all) do
    require 'sparql/grammar/terminals11'

    @terminals = [
      [:ANON,                 SPARQL::Grammar::Terminals::ANON],
      [:NIL,                  SPARQL::Grammar::Terminals::NIL],
      [:BLANK_NODE_LABEL,     SPARQL::Grammar::Terminals::BLANK_NODE_LABEL],
      [:IRIREF,               SPARQL::Grammar::Terminals::IRIREF],
      [:DOUBLE_POSITIVE,      SPARQL::Grammar::Terminals::DOUBLE_POSITIVE],
      [:DECIMAL_POSITIVE,     SPARQL::Grammar::Terminals::DECIMAL_POSITIVE],
      [:INTEGER_POSITIVE,     SPARQL::Grammar::Terminals::INTEGER_POSITIVE],
      [:DOUBLE_NEGATIVE,      SPARQL::Grammar::Terminals::DOUBLE_NEGATIVE],
      [:DECIMAL_NEGATIVE,     SPARQL::Grammar::Terminals::DECIMAL_NEGATIVE],
      [:INTEGER_NEGATIVE,     SPARQL::Grammar::Terminals::INTEGER_NEGATIVE],
      [:DOUBLE,               SPARQL::Grammar::Terminals::DOUBLE],
      [:DECIMAL,              SPARQL::Grammar::Terminals::DECIMAL],
      [:INTEGER,              SPARQL::Grammar::Terminals::INTEGER],
      [:LANGTAG,              SPARQL::Grammar::Terminals::LANGTAG],
      [:PNAME_LN,             SPARQL::Grammar::Terminals::PNAME_LN],
      [:PNAME_NS,             SPARQL::Grammar::Terminals::PNAME_NS],
      [:STRING_LITERAL_LONG1, SPARQL::Grammar::Terminals::STRING_LITERAL_LONG1],
      [:STRING_LITERAL_LONG2, SPARQL::Grammar::Terminals::STRING_LITERAL_LONG2],
      [:STRING_LITERAL1,      SPARQL::Grammar::Terminals::STRING_LITERAL1],
      [:STRING_LITERAL2,      SPARQL::Grammar::Terminals::STRING_LITERAL2],
      [:VAR1,                 SPARQL::Grammar::Terminals::VAR1],
      [:VAR2,                 SPARQL::Grammar::Terminals::VAR2],
      [nil,                   %r(ABS|ADD|ALL|ASC|ASK|AS|BASE|BINDINGS|BIND
                                |BNODE|BOUND|BY|CEIL|CLEAR|COALESCE|CONCAT
                                |CONSTRUCT|CONTAINS|COPY|COUNT|CREATE|DATATYPE|DAY
                                |DEFAULT|DELETE\sDATA|DELETE\sWHERE|DELETE
                                |DESCRIBE|DESC|DISTINCT|DROP|ENCODE_FOR_URI|EXISTS
                                |FILTER|FLOOR|FROM|GRAPH|GROUP_CONCAT|GROUP|HAVING
                                |HOURS|IF|INSERT\sDATA|INSERT|INTO|IN|IRI
                                |LANGMATCHES|LANGTAG|LANG|LCASE|LIMIT|LOAD
                                |MAX|MD5|MINUS|MINUTES|MIN|MONTH|MOVE
                                |NAMED|NOT|NOW|OFFSET|OPTIONAL
                                |ORDER|PREFIX|RAND|REDUCED|REGEX|ROUND|SAMPLE|SECONDS
                                |SELECT|SEPARATOR|SERVICE
                                |SHA1|SHA224|SHA256|SHA384|SHA512
                                |STRDT|STRENDS|STRLAN|STRLEN|STRSTARTS|SUBSTR|STR|SUM
                                |TIMEZONE|TO|TZ|UCASE|UNDEF|UNION|URI|USING
                                |WHERE|WITH|YEAR
                                |isBLANK|isIRI|isLITERAL|isNUMERIC|sameTerm
                                |true
                                |false
                              )xi],
      [nil,                   %r(&&|!=|!|<=|>=|\^\^|\|\||[\(\),.;\[\]\{\}\+\-=<>\?\^\|\*\/a])],
    ]
    
    @unescape_terms = [
      :IRIREF,
      :STRING_LITERAL1, :STRING_LITERAL2, :STRING_LITERAL_LONG1, :STRING_LITERAL_LONG2,
      :VAR1, :VAR2
    ]
  end
  
  describe "when unescaping Unicode input" do
    # @see http://www.w3.org/TR/rdf-sparql-query/#codepointEscape

    it "unescapes \\uXXXX codepoint escape sequences" do
      inputs = {
        %q(\u0020)       => %q( ),
        %q(<ab\u00E9xy>) => %Q(<ab\xC3\xA9xy>),
        %q(\u03B1:a)     => %Q(\xCE\xB1:a),
        %q(a\u003Ab)     => %Q(a\x3Ab),
      }
      inputs.each do |input, output|
        output.encode!(Encoding::UTF_8)
        EBNF::LL1::Lexer.unescape_codepoints(input).should == output
      end
    end

    it "unescapes \\UXXXXXXXX codepoint escape sequences" do
      inputs = {
        %q(\U00000020)   => %q( ),
        %q(\U00010000)   => %Q(\xF0\x90\x80\x80),
        %q(\U000EFFFF)   => %Q(\xF3\xAF\xBF\xBF),
      }
      inputs.each do |input, output|
        output.encode!(Encoding::UTF_8)
        EBNF::LL1::Lexer.unescape_codepoints(input).should == output
      end
    end
  end

  describe "when unescaping strings" do
    # @see http://www.w3.org/TR/rdf-sparql-query/#grammarEscapes

    EBNF::LL1::Lexer::ESCAPE_CHARS.each do |escaped, unescaped|
      it "unescapes #{escaped} escape sequences" do
        EBNF::LL1::Lexer.unescape_string(escaped).should == unescaped
      end
    end
  end

  describe "when matching Unicode input" do
    it "matches the PN_CHARS_BASE production correctly" do
      strings = [
        ["\xC3\x80",         "\xC3\x96"],         # \u00C0-\u00D6
        ["\xC3\x98",         "\xC3\xB6"],         # \u00D8-\u00F6
        ["\xC3\xB8",         "\xCB\xBF"],         # \u00F8-\u02FF
        ["\xCD\xB0",         "\xCD\xBD"],         # \u0370-\u037D
        ["\xCD\xBF",         "\xE1\xBF\xBF"],     # \u037F-\u1FFF
        ["\xE2\x80\x8C",     "\xE2\x80\x8D"],     # \u200C-\u200D
        ["\xE2\x81\xB0",     "\xE2\x86\x8F"],     # \u2070-\u218F
        ["\xE2\xB0\x80",     "\xE2\xBF\xAF"],     # \u2C00-\u2FEF
        ["\xE3\x80\x81",     "\xED\x9F\xBF"],     # \u3001-\uD7FF
        ["\xEF\xA4\x80",     "\xEF\xB7\x8F"],     # \uF900-\uFDCF
        ["\xEF\xB7\xB0",     "\xEF\xBF\xBD"],     # \uFDF0-\uFFFD
        ["\xF0\x90\x80\x80", "\xF3\xAF\xBF\xBF"], # \u{10000}-\u{EFFFF}]
      ]
      strings.each do |range|
        range.each do |string|
          string.encode!(Encoding::UTF_8)
          string.should match(SPARQL::Grammar::Terminals::PN_CHARS_BASE)
        end
      end
    end
    
    it "matches kanji test input" do
      tokenize('"食"') do |tokens|
        tokens.should have(1).element
        tokens.first.type.should == :STRING_LITERAL2
      end
      tokenize('食:食べる') do |tokens|
        tokens.should have(1).elements
        tokens.first.type.should == :PNAME_LN
      end
    end
  end

  describe "when tokenizing numeric literals" do
    it "tokenizes unsigned integer literals" do
      tokenize(%q(42)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :INTEGER
        tokens.first.value.should == "42"
      end
    end

    it "tokenizes positive integer literals" do
      tokenize(%q(+42)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :INTEGER_POSITIVE
        tokens.first.value.should == "+42"
      end
    end

    it "tokenizes negative integer literals" do
      tokenize(%q(-42)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :INTEGER_NEGATIVE
        tokens.first.value.should == "-42"
      end
    end

    it "tokenizes unsigned decimal literals" do
      tokenize(%q(3.1415)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :DECIMAL
        tokens.first.value.should == "3.1415"
      end
    end

    it "tokenizes positive decimal literals" do
      tokenize(%q(+3.1415)) do |tokens|
        tokens.should have(1).element
        tokens.last.type.should  == :DECIMAL_POSITIVE
        tokens.last.value.should == "+3.1415"
      end
    end

    it "tokenizes negative decimal literals" do
      tokenize(%q(-3.1415)) do |tokens|
        tokens.should have(1).element
        tokens.last.type.should  == :DECIMAL_NEGATIVE
        tokens.last.value.should == "-3.1415"
      end
    end

    it "tokenizes unsigned double literals" do
      tokenize(%q(1e6)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :DOUBLE
        tokens.first.value.should == "1e6"
      end
    end

    it "tokenizes positive double literals" do
      tokenize(%q(+1e6)) do |tokens|
        tokens.should have(1).element
        tokens.last.type.should  == :DOUBLE_POSITIVE
        tokens.last.value.should == "+1e6"
      end
    end

    it "tokenizes negative double literals" do
      tokenize(%q(-1e6)) do |tokens|
        tokens.should have(1).element
        tokens.last.type.should  == :DOUBLE_NEGATIVE
        tokens.last.value.should == "-1e6"
      end
    end
  end

  describe "when tokenizing string literals" do
    it "tokenizes single-quoted string literals" do
      tokenize(%q('Hello, world!')) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :STRING_LITERAL1
        tokens.first.value.should == %q('Hello, world!')
      end
    end

    it "tokenizes double-quoted string literals" do
      tokenize(%q("Hello, world!")) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :STRING_LITERAL2
        tokens.first.value.should == %q("Hello, world!")
      end
    end

    it "tokenizes long single-quoted string literals" do
      tokenize(%q('''Hello, world!''')) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :STRING_LITERAL_LONG1
        tokens.first.value.should == %q('''Hello, world!''')
      end
    end

    it "tokenizes long double-quoted string literals" do
      tokenize(%q("""Hello, world!""")) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :STRING_LITERAL_LONG2
        tokens.first.value.should == %q("""Hello, world!""")
      end
    end
  end

  describe "when tokenizing blank nodes" do
    it "tokenizes labelled blank nodes" do
      tokenize(%q(_:foobar)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :BLANK_NODE_LABEL
        tokens.first.value.should == "_:foobar"
      end
    end

    it "tokenizes NIL" do
      tokenize(%q(()), %q(( )), %q((  ))) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :NIL
      end
    end

    it "tokenizes anonymous blank nodes" do
      tokenize(%q([]), %q([ ])) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :ANON
      end
    end
  end

  describe "when tokenizing variables" do
    it "tokenizes variables prefixed with '?'" do
      tokenize(%q(?foo)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :VAR1
        tokens.first.value.should == "?foo"
      end
    end

    it "tokenizes variables prefixed with '$'" do
      tokenize(%q($foo)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :VAR2
        tokens.first.value.should == "$foo"
      end
    end
  end

  describe "when tokenizing IRI references" do
    it "tokenizes absolute IRI references" do
      tokenize(%q(<http://example.org/foobar>)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :IRIREF
        tokens.first.value.should == '<http://example.org/foobar>'
      end
    end

    it "tokenizes relative IRI references" do
      tokenize(%q(<foobar>)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :IRIREF
        tokens.first.value.should == '<foobar>'
      end
    end
  end

  describe "when tokenizing prefixes" do
    it "tokenizes the empty prefix" do
      tokenize(%q(:)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :PNAME_NS
        tokens.first.value.should == ":"
      end
    end

    it "tokenizes labelled prefixes" do
      tokenize(%q(dc:)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should  == :PNAME_NS
        tokens.first.value.should == "dc:"
      end
    end
  end

  describe "when tokenizing prefixed names" do
    it "tokenizes prefixed names" do
      tokenize(%q(dc:title)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should == :PNAME_LN
        tokens.first.value.should == "dc:title"
      end
    end

    it "tokenizes prefixed names having an empty prefix label" do
      tokenize(%q(:title)) do |tokens|
        tokens.should have(1).element
        tokens.first.type.should == :PNAME_LN
        tokens.first.value.should == ":title"
      end
    end
  end

  describe "when tokenizing RDF literals" do
    it "tokenizes language-tagged literals" do
      tokenize(%q("Hello, world!"@en)) do |tokens|
        tokens.should have(2).elements
        tokens[0].type.should  == :STRING_LITERAL2
        tokens[0].value.should == %q("Hello, world!")
        tokens[1].type.should  == :LANGTAG
        tokens[1].value.should == "@en"
      end
      tokenize(%q("Hello, world!"@en-US)) do |tokens|
        tokens.should have(2).elements
        tokens[0].type.should  == :STRING_LITERAL2
        tokens[0].value.should == %q("Hello, world!")
        tokens[1].type.should  == :LANGTAG
        tokens[1].value.should == '@en-US'
      end
    end

    it "tokenizes datatyped literals" do
      tokenize(%q('3.1415'^^<http://www.w3.org/2001/XMLSchema#double>)) do |tokens|
        tokens.should have(3).elements
        tokens[0].type.should  == :STRING_LITERAL1
        tokens[0].value.should == %q('3.1415')
        tokens[1].type.should  == nil
        tokens[1].value.should == '^^'
        tokens[2].type.should  == :IRIREF
        tokens[2].value.should == "<http://www.w3.org/2001/XMLSchema#double>"
      end

      tokenize(%q("3.1415"^^<http://www.w3.org/2001/XMLSchema#double>)) do |tokens|
        tokens.should have(3).elements
        tokens[0].type.should  == :STRING_LITERAL2
        tokens[0].value.should == %q("3.1415")
        tokens[1].type.should  == nil
        tokens[1].value.should == '^^'
        tokens[2].type.should  == :IRIREF
        tokens[2].value.should == "<http://www.w3.org/2001/XMLSchema#double>"
      end
    end
  end

  describe "when tokenizing delimiters" do
    %w|^^ { } ( ) [ ] , ; .|.each do |delimiter|
      it "tokenizes the #{delimiter.inspect} delimiter" do
        tokenize(delimiter) do |tokens|
          tokens.should have(1).element
          tokens.first.type.should  == nil
          tokens.first.value.should == delimiter
        end
      end
    end
  end

  describe "when tokenizing operators" do
    %w(a || && != <= >= ! = < > + - * /).each do |operator|
      it "tokenizes the #{operator.inspect} operator" do
        tokenize(operator) do |tokens|
          tokens.should have(1).element
          tokens.first.type.should  == nil
          tokens.first.value.should == operator
        end
      end
    end
  end

  describe "when tokenizing keywords" do
    (%w{
       ABS ADD ALL AS ASC ASK BASE BIND BINDINGS
       BNODE BOUND BY CEIL CLEAR COALESCE CONCAT
       CONSTRUCT CONTAINS COPY COUNT CREATE DATATYPE DAY
       DEFAULT DELETE DESC
       DESCRIBE DISTINCT DROP ENCODE_FOR_URI EXISTS
       FILTER FLOOR FROM GRAPH GROUP_CONCAT GROUP HAVING
       HOURS IF INSERT INTO IN IRI
       LANGMATCHES LANGTAG LANG LCASE LIMIT LOAD
       MAX MD5 MINUS MINUTES MIN MONTH MOVE
       NAMED NOT NOW OFFSET OPTIONAL
       ORDER PREFIX RAND REDUCED REGEX ROUND SAMPLE SECONDS
       SELECT SEPARATOR SERVICE
       SHA1 SHA224 SHA256 SHA384 SHA512
       STRDT STRENDS STRLAN STRLEN STRSTARTS SUBSTR STR SUM
       TIMEZONE TO TZ UCASE UNDEF UNION URI USING
       WHERE WITH YEAR
       isBLANK isIRI isLITERAL isNUMERIC sameTerm
       true
       false
    } + [
      "DELETE DATA", "DELETE WHERE", "INSERT DATA",
    ]).sort.each do |keyword|
      it "tokenizes the #{keyword} keyword" do
        tokenize(keyword, keyword.upcase, keyword.downcase) do |tokens|
          tokens.should have(1).element
          tokens.first.type.should  == nil
          tokens.first.value.downcase.should == keyword.downcase
        end
      end
    end
  end

  describe "when handling comments" do
    it "ignores the remainder of the current line" do
      tokenize("# ?foo ?bar", "# ?foo ?bar\n", "# ?foo ?bar\r\n") do |tokens|
        tokens.should have(0).elements
      end
    end

    it "ignores leading whitespace" do
      tokenize(" # ?foo ?bar", "\n# ?foo ?bar", "\r\n# ?foo ?bar") do |tokens|
        tokens.should have(0).elements
      end
    end

    it "resumes tokenization from the following line" do
      tokenize("# ?foo\n?bar", "# ?foo\r\n?bar") do |tokens|
        tokens.should have(1).elements
        tokens.first.type.should  == :VAR1
        tokens.first.value.should == "?bar"
      end
    end
  end

  describe "when skipping white space" do
    inputs = {
      ""     => 1,
      "\n"   => 2,
      "\n\n" => 3,
      "\r\n" => 2,
    }
    inputs.each do |input, lineno|
      it "gets line number #{lineno} for #{input.inspect}" do
        lexer = EBNF::LL1::Lexer.tokenize(input, @terminals)
        lexer.to_a # consumes the input
        lexer.lineno.should == lineno
      end
    end
  end

  describe "when yielding tokens" do
    it "annotates tokens with the current line number" do
      tokenize("1\n2\n3\n4") do |tokens|
        tokens.should have(4).elements
        4.times { |line| tokens[line].lineno.should == line + 1 }
      end
    end
  end

  describe "when encountering invalid input" do
    it "raises a lexer error" do
      expect { tokenize("SELECT foo WHERE {}") }.to raise_error(EBNF::LL1::Lexer::Error)
    end

    it "reports the invalid token which triggered the error" do
      begin
        tokenize("SELECT foo WHERE {}")
      rescue EBNF::LL1::Lexer::Error => error
        error.token.should  == 'foo'
      end
      begin
        tokenize("SELECT ?foo WHERE { bar }")
      rescue EBNF::LL1::Lexer::Error => error
        error.token.should  == 'bar'
      end
    end

    it "reports the correct token which triggered the error" do
      begin
        tokenize("SELECT foo#bar\nWHERE {}")
      rescue EBNF::LL1::Lexer::Error => error
        error.token.should  == 'foo'
      end
    end

    it "reports the line number where the error occurred" do
      begin
        tokenize("SELECT foo WHERE {}")
      rescue EBNF::LL1::Lexer::Error => error
        error.lineno.should == 1
      end
      begin
        tokenize("SELECT\nfoo WHERE {}")
      rescue EBNF::LL1::Lexer::Error => error
        error.lineno.should == 2
      end
    end
  end

  describe "when tokenizing entire query strings" do
    it "tokenizes ASK queries" do
      query = "ASK WHERE { ?s ?p ?o . }"
      tokenize(query) do |tokens|
        tokens.should have(8).elements
      end
    end

    it "tokenizes SELECT queries" do
      query = "SELECT * WHERE { ?s ?p ?o . }"
      tokenize(query) do |tokens|
        tokens.should have(9).elements
      end
    end

    it "tokenizes CONSTRUCT queries" do
      query = "CONSTRUCT { ?s ?p ?o . }"
      tokenize(query) do |tokens|
        tokens.should have(7).elements
      end
    end

    it "tokenizes DESCRIBE queries" do
      query = "DESCRIBE ?s WHERE { ?s ?p ?o . }"
      tokenize(query) do |tokens|
        tokens.should have(9).elements
      end
    end
  end

  def tokenize(*inputs, &block)
    options = inputs.last.is_a?(Hash) ? inputs.pop : {}
    inputs.each do |input|
      tokens = EBNF::LL1::Lexer.tokenize(input, @terminals, :unescape_terms => @unescape_terms)
      tokens.should be_a(EBNF::LL1::Lexer)
      block.call(tokens.to_a)
    end
  end
end
