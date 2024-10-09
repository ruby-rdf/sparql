# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'ebnf'
require 'ebnf/ll1/lexer'
require 'sparql/grammar'

describe EBNF::LL1::Lexer do
  before(:all) do

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
      [:LANG_DIR,             SPARQL::Grammar::Terminals::LANG_DIR],
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
                                |LANGMATCHES|LANG_DIR|LANG|LCASE|LIMIT|LOAD
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
    # @see http://www.w3.org/TR/sparql11-query/#codepointEscape

    it "unescapes \\uXXXX codepoint escape sequences" do
      inputs = {
        %q(\u0020)       => %q( ),
        %q(<ab\u00E9xy>) => %Q(<ab\xC3\xA9xy>),
        %q(\u03B1:a)     => %Q(\xCE\xB1:a),
        %q(a\u003Ab)     => %Q(a\x3Ab),
      }
      inputs.each do |input, output|
        output.encode!(Encoding::UTF_8)
        expect(EBNF::LL1::Lexer.unescape_codepoints(input)).to eq output
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
        expect(EBNF::LL1::Lexer.unescape_codepoints(input)).to eq output
      end
    end
  end

  describe "when unescaping strings" do
    # @see http://www.w3.org/TR/sparql11-query/#grammarEscapes

    EBNF::LL1::Lexer::ESCAPE_CHARS.each do |escaped, unescaped|
      it "unescapes #{escaped} escape sequences" do
        expect(EBNF::LL1::Lexer.unescape_string(escaped)).to eq unescaped
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
          expect(string).to match(SPARQL::Grammar::Terminals::PN_CHARS_BASE)
        end
      end
    end
    
    it "matches kanji test input" do
      tokenize('"食"') do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :STRING_LITERAL2
      end
      tokenize('食:食べる') do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :PNAME_LN
      end
    end
  end

  describe "when tokenizing numeric literals" do
    it "tokenizes unsigned integer literals" do
      tokenize(%q(42)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :INTEGER
        expect(tokens.first.value).to eq "42"
      end
    end

    it "tokenizes positive integer literals" do
      tokenize(%q(+42)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :INTEGER_POSITIVE
        expect(tokens.first.value).to eq "+42"
      end
    end

    it "tokenizes negative integer literals" do
      tokenize(%q(-42)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :INTEGER_NEGATIVE
        expect(tokens.first.value).to eq "-42"
      end
    end

    it "tokenizes unsigned decimal literals" do
      tokenize(%q(3.1415)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :DECIMAL
        expect(tokens.first.value).to eq "3.1415"
      end
    end

    it "tokenizes positive decimal literals" do
      tokenize(%q(+3.1415)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.last.type).to eq :DECIMAL_POSITIVE
        expect(tokens.last.value).to eq "+3.1415"
      end
    end

    it "tokenizes negative decimal literals" do
      tokenize(%q(-3.1415)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.last.type).to eq :DECIMAL_NEGATIVE
        expect(tokens.last.value).to eq "-3.1415"
      end
    end

    it "tokenizes unsigned double literals" do
      tokenize(%q(1e6)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :DOUBLE
        expect(tokens.first.value).to eq "1e6"
      end
    end

    it "tokenizes positive double literals" do
      tokenize(%q(+1e6)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.last.type).to eq :DOUBLE_POSITIVE
        expect(tokens.last.value).to eq "+1e6"
      end
    end

    it "tokenizes negative double literals" do
      tokenize(%q(-1e6)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.last.type).to eq :DOUBLE_NEGATIVE
        expect(tokens.last.value).to eq "-1e6"
      end
    end
  end

  describe "when tokenizing string literals" do
    it "tokenizes single-quoted string literals" do
      tokenize(%q('Hello, world!')) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :STRING_LITERAL1
        expect(tokens.first.value).to eq %q('Hello, world!')
      end
    end

    it "tokenizes double-quoted string literals" do
      tokenize(%q("Hello, world!")) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :STRING_LITERAL2
        expect(tokens.first.value).to eq %q("Hello, world!")
      end
    end

    it "tokenizes long single-quoted string literals" do
      tokenize(%q('''Hello, world!''')) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :STRING_LITERAL_LONG1
        expect(tokens.first.value).to eq %q('''Hello, world!''')
      end
    end

    it "tokenizes long double-quoted string literals" do
      tokenize(%q("""Hello, world!""")) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :STRING_LITERAL_LONG2
        expect(tokens.first.value).to eq %q("""Hello, world!""")
      end
    end
  end

  describe "when tokenizing blank nodes" do
    it "tokenizes labelled blank nodes" do
      tokenize(%q(_:foobar)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :BLANK_NODE_LABEL
        expect(tokens.first.value).to eq "_:foobar"
      end
    end

    it "tokenizes NIL" do
      tokenize(%q(()), %q(( )), %q((  ))) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :NIL
      end
    end

    it "tokenizes anonymous blank nodes" do
      tokenize(%q([]), %q([ ])) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :ANON
      end
    end
  end

  describe "when tokenizing variables" do
    it "tokenizes variables prefixed with '?'" do
      tokenize(%q(?foo)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :VAR1
        expect(tokens.first.value).to eq "?foo"
      end
    end

    it "tokenizes variables prefixed with '$'" do
      tokenize(%q($foo)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :VAR2
        expect(tokens.first.value).to eq "$foo"
      end
    end
  end

  describe "when tokenizing IRI references" do
    it "tokenizes absolute IRI references" do
      tokenize(%q(<http://example.org/foobar>)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :IRIREF
        expect(tokens.first.value).to eq '<http://example.org/foobar>'
      end
    end

    it "tokenizes relative IRI references" do
      tokenize(%q(<foobar>)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :IRIREF
        expect(tokens.first.value).to eq '<foobar>'
      end
    end
  end

  describe "when tokenizing prefixes" do
    it "tokenizes the empty prefix" do
      tokenize(%q(:)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :PNAME_NS
        expect(tokens.first.value).to eq ":"
      end
    end

    it "tokenizes labelled prefixes" do
      tokenize(%q(dc:)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :PNAME_NS
        expect(tokens.first.value).to eq "dc:"
      end
    end
  end

  describe "when tokenizing prefixed names" do
    it "tokenizes prefixed names" do
      tokenize(%q(dc:title)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :PNAME_LN
        expect(tokens.first.value).to eq "dc:title"
      end
    end

    it "tokenizes prefixed names having an empty prefix label" do
      tokenize(%q(:title)) do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :PNAME_LN
        expect(tokens.first.value).to eq ":title"
      end
    end
  end

  describe "when tokenizing RDF literals" do
    it "tokenizes language-tagged literals" do
      tokenize(%q("Hello, world!"@en)) do |tokens|
        expect(tokens.length).to eq 2
        expect(tokens[0].type).to eq :STRING_LITERAL2
        expect(tokens[0].value).to eq %q("Hello, world!")
        expect(tokens[1].type).to eq :LANG_DIR
        expect(tokens[1].value).to eq "@en"
      end
      tokenize(%q("Hello, world!"@en-US)) do |tokens|
        expect(tokens.length).to eq 2
        expect(tokens[0].type).to eq :STRING_LITERAL2
        expect(tokens[0].value).to eq %q("Hello, world!")
        expect(tokens[1].type).to eq :LANG_DIR
        expect(tokens[1].value).to eq "@en-US"
      end
    end

    it "tokenizes datatyped literals" do
      tokenize(%q('3.1415'^^<http://www.w3.org/2001/XMLSchema#double>)) do |tokens|
        expect(tokens.length).to eq 3
        expect(tokens[0].type).to eq :STRING_LITERAL1
        expect(tokens[0].value).to eq %q('3.1415')
        expect(tokens[1].type).to be_nil
        expect(tokens[1].value).to eq "^^"
        expect(tokens[2].type).to eq :IRIREF
        expect(tokens[2].value).to eq "<http://www.w3.org/2001/XMLSchema#double>"
      end

      tokenize(%q("3.1415"^^<http://www.w3.org/2001/XMLSchema#double>)) do |tokens|
      expect(tokens.length).to eq 3
      expect(tokens[0].type).to eq :STRING_LITERAL2
      expect(tokens[0].value).to eq %q("3.1415")
      expect(tokens[1].type).to be_nil
      expect(tokens[1].value).to eq "^^"
      expect(tokens[2].type).to eq :IRIREF
      expect(tokens[2].value).to eq "<http://www.w3.org/2001/XMLSchema#double>"
      end
    end
  end

  describe "when tokenizing delimiters" do
    %w|^^ { } ( ) [ ] , ; .|.each do |delimiter|
      it "tokenizes the #{delimiter.inspect} delimiter" do
        tokenize(delimiter) do |tokens|
          expect(tokens.length).to eq 1
          expect(tokens.first.type).to eq nil
          expect(tokens.first.value).to eq delimiter
        end
      end
    end
  end

  describe "when tokenizing operators" do
    %w(a || && != <= >= ! = < > + - * /).each do |operator|
      it "tokenizes the #{operator.inspect} operator" do
        tokenize(operator) do |tokens|
          expect(tokens.length).to eq 1
          expect(tokens.first.type).to eq nil
          expect(tokens.first.value).to eq operator
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
       LANGMATCHES LANG_DIR LANG LCASE LIMIT LOAD
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
          expect(tokens.length).to eq 1
          expect(tokens.first.type).to eq nil
          expect(tokens.first.value.downcase).to eq keyword.downcase
        end
      end
    end
  end

  describe "when handling comments" do
    it "ignores the remainder of the current line" do
      tokenize("# ?foo ?bar", "# ?foo ?bar\n", "# ?foo ?bar\r\n") do |tokens|
        expect(tokens).to be_empty
      end
    end

    it "ignores leading whitespace" do
      tokenize(" # ?foo ?bar", "\n# ?foo ?bar", "\r\n# ?foo ?bar") do |tokens|
        expect(tokens).to be_empty
      end
    end

    it "resumes tokenization from the following line" do
      tokenize("# ?foo\n?bar", "# ?foo\r\n?bar") do |tokens|
        expect(tokens.length).to eq 1
        expect(tokens.first.type).to eq :VAR1
        expect(tokens.first.value).to eq "?bar"
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
        lexer = EBNF::LL1::Lexer.tokenize(input, @terminals, whitespace: SPARQL::Grammar::Terminals::WS)
        lexer.to_a # consumes the input
        expect(lexer.lineno).to eq lineno
      end
    end
  end

  describe "when yielding tokens" do
    it "annotates tokens with the current line number" do
      tokenize("1\n2\n3\n4") do |tokens|
        expect(tokens.length).to eq 4
        4.times { |line| expect(tokens[line].lineno).to eq line + 1 }
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
        expect(error.token).to eq 'foo'
      end
      begin
        tokenize("SELECT ?foo WHERE { bar }")
      rescue EBNF::LL1::Lexer::Error => error
        expect(error.token).to eq 'bar'
      end
    end

    it "reports the correct token which triggered the error" do
      begin
        tokenize("SELECT foo#bar\nWHERE {}")
      rescue EBNF::LL1::Lexer::Error => error
        expect(error.token).to eq 'foo'
      end
    end

    it "reports the line number where the error occurred" do
      begin
        tokenize("SELECT foo WHERE {}")
      rescue EBNF::LL1::Lexer::Error => error
        expect(error.lineno).to eq 1
      end
      begin
        tokenize("SELECT\nfoo WHERE {}")
      rescue EBNF::LL1::Lexer::Error => error
        expect(error.lineno).to eq 2
      end
    end
  end

  describe "when tokenizing entire query strings" do
    it "tokenizes ASK queries" do
      query = "ASK WHERE { ?s ?p ?o . }"
      tokenize(query) do |tokens|
        expect(tokens.length).to eq 8
      end
    end

    it "tokenizes SELECT queries" do
      query = "SELECT * WHERE { ?s ?p ?o . }"
      tokenize(query) do |tokens|
        expect(tokens.length).to eq 9
      end
    end

    it "tokenizes CONSTRUCT queries" do
      query = "CONSTRUCT { ?s ?p ?o . }"
      tokenize(query) do |tokens|
        expect(tokens.length).to eq 7
      end
    end

    it "tokenizes DESCRIBE queries" do
      query = "DESCRIBE ?s WHERE { ?s ?p ?o . }"
      tokenize(query) do |tokens|
        expect(tokens.length).to eq 9
      end
    end
  end

  def tokenize(*inputs, &block)
    options = inputs.last.is_a?(Hash) ? inputs.pop : {}
    inputs.each do |input|
      tokens = EBNF::LL1::Lexer.tokenize(input, @terminals,
                                        unescape_terms: @unescape_terms,
                                        whitespace: SPARQL::Grammar::Terminals::WS)
      expect(tokens).to be_a(EBNF::LL1::Lexer)
      block.call(tokens.to_a)
    end
  end
end
