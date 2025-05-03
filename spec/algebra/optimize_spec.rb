$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'sparql/client'

include SPARQL::Algebra

describe SPARQL::Algebra::Query do
  describe :optimize do
    {
      "prefix": {
        input: %q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ex:x1 ex:p2 ex:x2)))),
        expect: %q(
          (bgp (triple <http://example.org/x1> <http://example.org/p2> <http://example.org/x2>)))
      },
      "base": {
        input: %q(
          (base <http://example.org/>
            (bgp (triple <x1> <p2> <x2>)))),
        expect: %q(
          (bgp (triple <http://example.org/x1> <http://example.org/p2> <http://example.org/x2>)))
      },
      "join – empty (lhs)": {
        input: %q(
          (prefix ((ex: <http://example.org/>))
           (join
            (bgp)
            (bgp (triple ex:who ex:schoolHomepage ?schoolPage))))),
        expect: %q(
          (bgp (triple <http://example.org/who> <http://example.org/schoolHomepage> ?schoolPage)))
      },
      "join – empty (rhs)": {
        input: %q(
          (prefix ((ex: <http://example.org/>))
           (join
            (bgp (triple ex:who ex:schoolHomepage ?schoolPage))
            (bgp)))),
        expect: %q(
          (bgp (triple <http://example.org/who> <http://example.org/schoolHomepage> ?schoolPage)))
      },
      "join empty (both)": {
        input: %q(
          (prefix ((ex: <http://example.org/>))
           (join (bgp) (bgp)))),
        expect: %q(
          (bgp))
      },
      "left join empty lhs with filter expression": {
        input: %q{
          (prefix ((: <http://example/>))
            (leftjoin
              (bgp)
              (bgp (triple ?y :q ?w))
              (= ?v 2)))},
        expect: %q{
          (filter (= ?v 2)
            (bgp (triple ?y <http://example/q> ?w)))},
        pending: "Figure out LHS optimization"
      },
      "left join empty lhs with no filter expression": {
        input: %q{
          (prefix ((: <http://example/>))
            (leftjoin
              (bgp)
              (bgp (triple ?y :q ?w))))},
        expect: %q{
          (bgp (triple ?y <http://example/q> ?w))},
        pending: "Figure out LHS optimization"
      },
      "left join empty rhs with filter expression": {
        input: %q{
          (prefix ((: <http://example/>))
            (leftjoin
              (bgp (triple ?y :q ?w))
              (bgp)
              (= ?v 2)))},
        expect: %q{
          (bgp (triple ?y <http://example/q> ?w))s}
      },
      "left join empty rhs with no filter expression": {
        input: %q{
          (prefix ((: <http://example/>))
            (leftjoin
              (bgp (triple ?y :q ?w))
              (bgp)))},
        expect: %q{
          (bgp (triple ?y <http://example/q> ?w))}
      },
      "left join empty both with filter expression": {
        input: %q{
          (prefix ((: <http://example/>))
            (leftjoin (bgp) (bgp) (= ?v 2)))},
        expect: %q{(bgp)}
      },
      "left join empty both with no filter expression": {
        input: %q{
          (prefix ((: <http://example/>))
            (leftjoin (bgp) (bgp)))},
        expect: %q{(bgp)},
      },
      "mimus empty lhs": {pending: true},
      "mimus empty rhs": {pending: true},
      "mimus empty both": {pending: true},
      "path reverse": {
        input: %q{(prefix ((: <http://example.org/>)) (path :z (reverse :p) ?v))},
        expect: %q{(path ?v <http://example.org/p> <http://example.org/z>)}
      },
      "path path*": {
        input: %q{
          (prefix ((: <http://example.org/>))
            (path :a (seq (seq :p0 (path* :p1)) :p2) ?v))
        },
        expect: %q{
          (sequence
            (bgp
              (triple ??s <http://example.org/p2> <http://example.org/a>)
              (triple ?v <http://example.org/p1> ??o))
            (path ??o (path* <http://example.org/p2>) ??s))
        },
        pending: "How to compare ND variables"
      },
      "sameTerm": {pending: true},
      "service": {pending: true},
      "union": {pending: true},
    }.each do |name, params|
      it name do
        pending(params[:pending]) if params[:pending]
        query = SPARQL::Algebra.parse(params[:input])
        optimized = query.optimize
        expected = SPARQL::Algebra.parse(params[:expect])
        expect(optimized).to produce(expected, {})
      end
    end
  end
end