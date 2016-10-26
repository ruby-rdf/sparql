require 'ebnf/ll1/lexer'

module SPARQL::Grammar
  module Terminals
    # Definitions of token regular expressions used for lexical analysis
  
    ##
    # Unicode regular expressions for Ruby 1.9+ with the Oniguruma engine.
    U_CHARS1         = Regexp.compile(<<-EOS.gsub(/\s+/, ''))
                         [\\u00C0-\\u00D6]|[\\u00D8-\\u00F6]|[\\u00F8-\\u02FF]|
                         [\\u0370-\\u037D]|[\\u037F-\\u1FFF]|[\\u200C-\\u200D]|
                         [\\u2070-\\u218F]|[\\u2C00-\\u2FEF]|[\\u3001-\\uD7FF]|
                         [\\uF900-\\uFDCF]|[\\uFDF0-\\uFFFD]|[\\u{10000}-\\u{EFFFF}]
                       EOS
    U_CHARS2         = Regexp.compile("\\u00B7|[\\u0300-\\u036F]|[\\u203F-\\u2040]").freeze
    IRI_RANGE        = Regexp.compile("[[^<>\"{}|^`\\\\]&&[^\\x00-\\x20]]").freeze

    # 26
    UCHAR                = EBNF::LL1::Lexer::UCHAR
    # 170s
    PERCENT              = /%[0-9A-Fa-f]{2}/.freeze
    # 172s
    PN_LOCAL_ESC         = /\\[_~\.\-\!$\&'\(\)\*\+,;=:\/\?\#@%]/.freeze
    # 169s
    PLX                  = /#{PERCENT}|#{PN_LOCAL_ESC}/.freeze
    # 153
    PN_CHARS_BASE        = /[A-Z]|[a-z]|#{U_CHARS1}/.freeze
    # 154
    PN_CHARS_U           = /_|#{PN_CHARS_BASE}/.freeze
    # 155
    VARNAME              = /(?:[0-9]|#{PN_CHARS_U})
                            (?:[0-9]|#{PN_CHARS_U}|#{U_CHARS2})*/x.freeze
    # 156
    PN_CHARS             = /-|[0-9]|#{PN_CHARS_U}|#{U_CHARS2}/.freeze
    PN_LOCAL_BODY        = /(?:(?:\.|:|#{PN_CHARS}|#{PLX})*(?:#{PN_CHARS}|:|#{PLX}))?/.freeze
    PN_CHARS_BODY        = /(?:(?:\.|#{PN_CHARS})*#{PN_CHARS})?/.freeze
    # 157
    PN_PREFIX            = /#{PN_CHARS_BASE}#{PN_CHARS_BODY}/.freeze
    # 158
    PN_LOCAL             = /(?:[0-9]|:|#{PN_CHARS_U}|#{PLX})#{PN_LOCAL_BODY}/.freeze
    # 144
    EXPONENT             = /[eE][+-]?[0-9]+/
    # 149
    ECHAR                = /\\[tbnrf\\"']/.freeze
    # 18
    IRIREF               = /<(?:#{IRI_RANGE}|#{UCHAR})*>/.freeze
    # 129
    PNAME_NS             = /#{PN_PREFIX}?:/.freeze
    # 130
    PNAME_LN             = /(?:#{PNAME_NS})(?:#{PN_LOCAL})/.freeze
    # 131
    BLANK_NODE_LABEL     = /_:(?:[0-9]|#{PN_CHARS_U})((#{PN_CHARS}|\.)*#{PN_CHARS})?/.freeze
    # 132
    VAR1                 = /\?#{VARNAME}/.freeze
    # 133
    VAR2                 = /\$#{VARNAME}/.freeze
    # 134
    LANGTAG              = /@[a-zA-Z]+(?:-[a-zA-Z0-9]+)*/.freeze
    # 135
    INTEGER              = /[0-9]+/.freeze
    # 136
    DECIMAL              = /(?:[0-9]*\.[0-9]+)/.freeze
    # 137
    DOUBLE               = /(?:[0-9]+\.[0-9]*#{EXPONENT}|\.?[0-9]+#{EXPONENT})/.freeze
    # 138
    INTEGER_POSITIVE     = /(\+)([0-9]+)/.freeze
    # 139
    DECIMAL_POSITIVE     = /(\+)([0-9]*\.[0-9]+)/.freeze
    # 140
    DOUBLE_POSITIVE      = /(\+)([0-9]+\.[0-9]*#{EXPONENT}|\.?[0-9]+#{EXPONENT})/.freeze
    # 141
    INTEGER_NEGATIVE     = /(\-)([0-9]+)/.freeze
    # 142
    DECIMAL_NEGATIVE     = /(\-)([0-9]*\.[0-9]+)/.freeze
    # 143
    DOUBLE_NEGATIVE      = /(\-)([0-9]+\.[0-9]*#{EXPONENT}|\.?[0-9]+#{EXPONENT})/.freeze
    # 145
    STRING_LITERAL1      = /'([^\'\\\n\r]|#{ECHAR}|#{UCHAR})*'/.freeze
    # 146
    STRING_LITERAL2      = /"([^\"\\\n\r]|#{ECHAR}|#{UCHAR})*"/.freeze
    # 147
    STRING_LITERAL_LONG1 = /'''((?:'|'')?(?:[^'\\]|#{ECHAR}|#{UCHAR}))*'''/m.freeze
    # 148
    STRING_LITERAL_LONG2 = /"""((?:"|"")?(?:[^"\\]|#{ECHAR}|#{UCHAR}))*"""/m.freeze

    # 151
    WS                   = /(?:\s|(?:#[^\n\r]*))+/m.freeze
    # 150
    NIL                  = /\(#{WS}*\)/m.freeze
    # 152
    ANON                 = /\[#{WS}*\]/m.freeze

    # String terminals, case insensitive
    STR_EXPR = %r(ABS|ADD|ALL|ASC|ASK|AS|AVG|BASE|BINDINGS|BIND
                 |BNODE|BOUND|BY|CEIL|CLEAR|COALESCE|CONCAT
                 |CONSTRUCT|CONTAINS|COPY|COUNT|CREATE|DATATYPE|DAY
                 |DEFAULT|DELETE#{WS}DATA|DELETE#{WS}WHERE|DELETE
                 |DESCRIBE|DESC|DISTINCT|DROP|ENCODE_FOR_URI|EXISTS
                 |FILTER|FLOOR|FROM|GRAPH|GROUP_CONCAT|GROUP|HAVING
                 |HOURS|IF|INSERT#{WS}DATA|INSERT|INTO|IN|IRI
                 |LANGMATCHES|LANGTAG|LANG|LCASE|LIMIT|LOAD
                 |MAX|MD5|MINUS|MINUTES|MIN|MONTH|MOVE
                 |NAMED|NOT|NOW|OFFSET|OPTIONAL
                 |ORDER|PREFIX|RAND|REDUCED|REGEX|REPLACE|ROUND|SAMPLE|SECONDS
                 |SELECT|SEPARATOR|SERVICE
                 |SHA1|SHA224|SHA256|SHA384|SHA512|SILENT
                 |STRAFTER|STRBEFORE|STRDT|STRENDS|STRLANG|STRLEN|STRSTARTS|STRUUID|SUBSTR|STR|SUM
                 |TIMEZONE|TO|TZ|UCASE|UNDEF|UNION|URI|USING|UUID|VALUES
                 |WHERE|WITH|YEAR
                 |isBLANK|isIRI|isURI|isLITERAL|isNUMERIC|sameTerm
                 |true
                 |false
                 |&&|!=|!|<=|>=|\^\^|\|\||[\(\),.;\[\]\{\}\+\-=<>\?\^\|\*\/a]
              )xim.freeze

    # Map terminals to canonical form
    STR_MAP = (%w{ABS ADD ALL ASC ASK AS AVG BASE BINDINGS BIND
      BNODE BOUND BY CEIL CLEAR COALESCE CONCAT
      CONSTRUCT CONTAINS COPY COUNT CREATE DATATYPE DAY
      DEFAULT DELETE
      DESCRIBE DESC DISTINCT DROP ENCODE_FOR_URI EXISTS
      FILTER FLOOR FROM GRAPH GROUP_CONCAT GROUP HAVING
      HOURS IF INSERT INTO IN IRI
      LANGMATCHES LANGTAG LANG LCASE LIMIT LOAD
      MAX MD5 MINUS MINUTES MIN MONTH MOVE
      NAMED NOT NOW OFFSET OPTIONAL
      ORDER PREFIX RAND REDUCED REGEX REPLACE ROUND SAMPLE SECONDS
      SELECT SEPARATOR SERVICE
      SHA1 SHA224 SHA256 SHA384 SHA512 SILENT
      STRAFTER STRBEFORE STRDT STRENDS STRLANG STRLEN STRSTARTS STRUUID SUBSTR STR SUM
      TIMEZONE TO TZ UCASE UNDEF UNION URI USING UUID
      VALUES WHERE WITH YEAR
      isBLANK isIRI isURI isLITERAL isNUMERIC sameTerm
      true false
    } + [
      "DELETE DATA",
      "DELETE WHERE",
      "INSERT DATA",
    ]).inject({}) {|memo, t| memo[t.downcase] = t; memo}.freeze
  end
end