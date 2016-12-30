$:.unshift File.expand_path("../..", __FILE__)
require 'spec_helper'
require 'algebra/algebra_helper'
require 'sparql/client'

include SPARQL::Algebra

describe SPARQL::Algebra::Query do
  EX = RDF::EX = RDF::Vocabulary.new('http://example.org/') unless const_defined?(:EX)

  context "shortcuts" do
    it "translates 'a' to rdf:type" do
      sse = SPARQL::Algebra.parse(%q((triple <a> a <b>)))
      expect(sse).to be_a(RDF::Statement)
      expect(sse.predicate).to eq RDF.type
      expect(sse.predicate.lexical).to eq 'a'
    end
  end

  context "BGPs" do
    context "querying for a specific statement" do
      let(:graph) {RDF::Graph.new.insert([EX.x1, EX.p1, EX.x2])}
      it "returns an empty solution sequence if the statement does not exist" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ex:x1 ex:p2 ex:x2)))))
        expect(query.execute(graph)).to be_empty
      end
    end

    context "querying for a literal" do
      let(:graph) {RDF::Graph.new.insert([EX.x1, EX.p1, RDF::Literal::Decimal.new(123.0)])}
      it "should return a sequence with an existing literal" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?s ex:p1 123.0)))))
        expect(query.execute(graph)).to have_result_set [{s: EX.x1}]
      end
    end

    context "triple pattern combinations" do
      let(:graph) {
        # Normally we would not want all of this crap in the graph for each
        # test, but this gives us the nice benefit that each test implicitly
        # tests returning only the correct results and not random other ones.
        RDF::Graph.new do |g|
          # simple patterns
          g << [EX.x1, EX.p, 1]
          g << [EX.x2, EX.p, 2]
          g << [EX.x3, EX.p, 3]

          # pattern with same variable twice
          g << [EX.x4, EX.psame, EX.x4]

          # pattern with variable across 2 patterns
          g << [EX.x5, EX.p3, EX.x3]
          g << [EX.x5, EX.p2, EX.x3]

          # pattern following a chain
          g << [EX.x6, EX.pchain, EX.target]
          g << [EX.target, EX.pchain2, EX.target2]
          g << [EX.target2, EX.pchain3, EX.target3]
        end
      }

      it "?s p o" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?s ex:p 1)))))
        expect(query.execute(graph)).to have_result_set([{ s: EX.x1 }])
      end

      it "s ?p o" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ex:x2 ?p 2)))))
        expect(query.execute(graph)).to have_result_set [ { p: EX.p } ]
      end

      it "s p ?o" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ex:x3 ex:p ?o)))))
        expect(query.execute(graph)).to have_result_set [ { o: RDF::Literal.new(3) } ]
      end

      it "?s p ?o" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?s ex:p ?o)))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x1, o: RDF::Literal.new(1) },
                                                       { s: EX.x2, o: RDF::Literal.new(2) },
                                                       { s: EX.x3, o: RDF::Literal.new(3) }]
      end

      it "?s ?p o" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?s ?p 3)))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x3, p: EX.p } ]
      end

      it "s ?p ?o" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ex:x1 ?p ?o)))))
        expect(query.execute(graph)).to have_result_set [ { p: EX.p, o: RDF::Literal(1) } ]
      end

      it "?s p o / ?s p1 o1" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?s ex:p3 ex:x3)
                 (triple ?s ex:p2 ex:x3)))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x5 } ]
      end

      it "?s1 p ?o1 / ?o1 p2 ?o2 / ?o2 p3 ?o3" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?s ex:pchain ?o)
                 (triple ?o ex:pchain2 ?o2)
                 (triple ?o2 ex:pchain3 ?o3)))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x6, o: EX.target, o2: EX.target2, o3: EX.target3 } ]
      end

      it "?same p ?same" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?same ex:psame ?same)))))
        expect(query.execute(graph)).to have_result_set [ { same: EX.x4 } ]
      end

      it "(distinct ?s)" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (distinct
              (project (?s)
                (bgp (triple ?s ?p ?o)))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x1 },
                                                       { s: EX.x2 },
                                                       { s: EX.x3 },
                                                       { s: EX.x4 },
                                                       { s: EX.x5 },
                                                       { s: EX.x6 },
                                                       { s: EX.target },
                                                       { s: EX.target2 }]
      end

      it "(filter (isLiteral ?o))" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (filter (isLiteral ?o)
              (bgp (triple ?s ex:p ?o))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x1, o: RDF::Literal.new(1) },
                                                       { s: EX.x2, o: RDF::Literal.new(2) },
                                                       { s: EX.x3, o: RDF::Literal.new(3) }]
      end

      it "(filter (< ?o 3))" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (filter (< ?o 3)
              (bgp (triple ?s ex:p ?o))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x1, o: RDF::Literal.new(1) },
                                                       { s: EX.x2, o: RDF::Literal.new(2) }]
      end

      it "(filter (exprlist (> ?o 1) (< ?o 3)))" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (filter (exprlist (> ?o 1) (< ?o 3))
              (bgp (triple ?s ex:p ?o))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x2, o: RDF::Literal.new(2) }]
      end

      it "(order ?o)" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (order (?o)
              (bgp (triple ?s ex:p ?o))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x1, o: RDF::Literal.new(1) },
                                                       { s: EX.x2, o: RDF::Literal.new(2) },
                                                       { s: EX.x3, o: RDF::Literal.new(3) }]
      end

      it "(order ((asc ?o)))" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (order ((asc ?o))
              (bgp (triple ?s ex:p ?o))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x1, o: RDF::Literal.new(1) },
                                                       { s: EX.x2, o: RDF::Literal.new(2) },
                                                       { s: EX.x3, o: RDF::Literal.new(3) }]
      end

      it "(order ((desc ?o)))" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (order ((desc ?o))
              (bgp (triple ?s ex:p ?o))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x3, o: RDF::Literal.new(3) },
                                                       { s: EX.x2, o: RDF::Literal.new(2) },
                                                       { s: EX.x1, o: RDF::Literal.new(1) }]
      end

      it "((order ?o) (table (vars ?o) (row (?o _:1)) (row (?o undef)) (row (?o \"example.org\")) (row (?o <http://www.example.org/>))))" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (order (?o)
              (table (vars ?o) (row (?o _:1)) (row (?o undef)) (row (?o "example.org")) (row (?o <http://www.example.org/>)))))))
        expect(query.execute(graph)).to have_result_set [ { },
                                                       { o: RDF::Node.new(1) },
                                                       { o: RDF::URI.new('http://www.example.org/') },
                                                       { o: RDF::Literal.new('example.org') }]
      end

      it "((order ?o) (table (vars ?o) (row (?o _:1)) (row (?o undef)) (row (?o \"example.org\")) (row (?o <http://www.example.org/>))))" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (order (?o ?o2)
              (join
                (table (vars ?o) (row (?o _:1)) (row (?o undef)) (row (?o "example.org")) (row (?o <http://www.example.org/>)))
                (table (vars ?o2) (row (?o2 _:2)) (row (?o2 undef)) (row (?o2 "example.org")) (row (?o2 <http://www.example.org/>))))))))
        expect(query.execute(graph)).to have_result_set [ { },
                                                       { o2: RDF::Node.new(2) },
                                                       { o2: RDF::URI.new('http://www.example.org/') },
                                                       { o2: RDF::Literal.new('example.org') },
                                                       { o: RDF::Node.new(1) },
                                                       { o: RDF::Node.new(1), o2: RDF::Node.new(2) },
                                                       { o: RDF::Node.new(1), o2: RDF::URI.new('http://www.example.org/') },
                                                       { o: RDF::Node.new(1), o2: RDF::Literal.new('example.org') },
                                                       { o: RDF::URI.new('http://www.example.org/') },
                                                       { o: RDF::URI.new('http://www.example.org/'), o2: RDF::Node.new(2) },
                                                       { o: RDF::URI.new('http://www.example.org/'), o2: RDF::URI.new('http://www.example.org/') },
                                                       { o: RDF::URI.new('http://www.example.org/'), o2: RDF::Literal.new('example.org') },
                                                       { o: RDF::Literal.new('example.org') },
                                                       { o: RDF::Literal.new('example.org'), o2: RDF::Node.new(2) },
                                                       { o: RDF::Literal.new('example.org'), o2: RDF::URI.new('http://www.example.org/') },
                                                       { o: RDF::Literal.new('example.org'), o2: RDF::Literal.new('example.org') }]
      end

      it "(order ((asc ?o) (desc ?o2)))" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (order ((asc ?o) (desc ?o2))
              (bgp (triple ?s ex:p ?o)
                   (triple ?s2 ex:p ?o2))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x1, o: RDF::Literal.new(1), s2: EX.x3, o2: RDF::Literal.new(3) },
                                                       { s: EX.x1, o: RDF::Literal.new(1), s2: EX.x2, o2: RDF::Literal.new(2) },
                                                       { s: EX.x1, o: RDF::Literal.new(1), s2: EX.x1, o2: RDF::Literal.new(1) },
                                                       { s: EX.x2, o: RDF::Literal.new(2), s2: EX.x3, o2: RDF::Literal.new(3) },
                                                       { s: EX.x2, o: RDF::Literal.new(2), s2: EX.x2, o2: RDF::Literal.new(2) },
                                                       { s: EX.x2, o: RDF::Literal.new(2), s2: EX.x1, o2: RDF::Literal.new(1) },
                                                       { s: EX.x3, o: RDF::Literal.new(3), s2: EX.x3, o2: RDF::Literal.new(3) },
                                                       { s: EX.x3, o: RDF::Literal.new(3), s2: EX.x2, o2: RDF::Literal.new(2) },
                                                       { s: EX.x3, o: RDF::Literal.new(3), s2: EX.x1, o2: RDF::Literal.new(1) }]
      end

      it "(project (?o) ?p ?o)" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (project (?o)
              (bgp (triple ex:x1 ?p ?o))))))
        expect(query.execute(graph)).to have_result_set [ { o: RDF::Literal(1) } ]
      end

      it "(reduced ?s)" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (reduced
              (project (?s)
                (bgp (triple ?s ?p ?o)))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x1 },
                                                       { s: EX.x2 },
                                                       { s: EX.x3 },
                                                       { s: EX.x4 },
                                                       { s: EX.x5 },
                                                       { s: EX.x6 },
                                                       { s: EX.target },
                                                       { s: EX.target2 }]
      end

      it "(slice _ 1)" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (slice _ 1
              (order (?s)
                (project (?s)
                  (bgp (triple ?s ?p ?o))))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.target }]
      end

      it "(slice 1 2)" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (slice 1 2
              (order (?s)
                (project (?s)
                  (bgp (triple ?s ?p ?o))))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.target2 }, { s: EX.x1 }]
      end

      it "(slice 5 _)" do
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (slice 5 _
              (order (?s)
                (project (?s)
                  (bgp (triple ?s ?p ?o))))))))
        expect(query.execute(graph)).to have_result_set [ { s: EX.x4 },
                                                       { s: EX.x5 },
                                                       { s: EX.x5 },
                                                       { s: EX.x6 } ]
      end

      # From sp2b benchmark, query 7 bgp 2
      it "?class3 p o / ?doc3 p2 ?class3 / ?doc3 p3 ?bag3 / ?bag3 ?member3 ?doc" do
        graph << [EX.class1, EX.subclass, EX.document]
        graph << [EX.class2, EX.subclass, EX.document]
        graph << [EX.class3, EX.subclass, EX.other]

        graph << [EX.doc1, EX.type, EX.class1]
        graph << [EX.doc2, EX.type, EX.class1]
        graph << [EX.doc3, EX.type, EX.class2]
        graph << [EX.doc4, EX.type, EX.class2]
        graph << [EX.doc5, EX.type, EX.class3]

        graph << [EX.doc1, EX.refs, EX.bag1]
        graph << [EX.doc2, EX.refs, EX.bag2]
        graph << [EX.doc3, EX.refs, EX.bag3]
        graph << [EX.doc5, EX.refs, EX.bag5]

        graph << [EX.bag1, RDF::Node.new('ref1'), EX.doc11]
        graph << [EX.bag1, RDF::Node.new('ref2'), EX.doc12]
        graph << [EX.bag1, RDF::Node.new('ref3'), EX.doc13]

        graph << [EX.bag2, RDF::Node.new('ref1'), EX.doc21]
        graph << [EX.bag2, RDF::Node.new('ref2'), EX.doc22]
        graph << [EX.bag2, RDF::Node.new('ref3'), EX.doc23]

        graph << [EX.bag3, RDF::Node.new('ref1'), EX.doc31]
        graph << [EX.bag3, RDF::Node.new('ref2'), EX.doc32]
        graph << [EX.bag3, RDF::Node.new('ref3'), EX.doc33]

        graph << [EX.bag5, RDF::Node.new('ref1'), EX.doc51]
        graph << [EX.bag5, RDF::Node.new('ref2'), EX.doc52]
        graph << [EX.bag5, RDF::Node.new('ref3'), EX.doc53]

        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?class3 ex:subclass ex:document)
                 (triple ?doc3 ex:type ?class3)
                 (triple ?doc3 ex:refs ?bag3)
                 (triple ?bag3 ?member3 ?doc)))))

        expect(query.execute(graph)).to have_result_set [
          { doc3: EX.doc1, class3: EX.class1, bag3: EX.bag1, member3: RDF::Node.new('ref1'), doc: EX.doc11 },
          { doc3: EX.doc1, class3: EX.class1, bag3: EX.bag1, member3: RDF::Node.new('ref2'), doc: EX.doc12 },
          { doc3: EX.doc1, class3: EX.class1, bag3: EX.bag1, member3: RDF::Node.new('ref3'), doc: EX.doc13 },
          { doc3: EX.doc2, class3: EX.class1, bag3: EX.bag2, member3: RDF::Node.new('ref1'), doc: EX.doc21 },
          { doc3: EX.doc2, class3: EX.class1, bag3: EX.bag2, member3: RDF::Node.new('ref2'), doc: EX.doc22 },
          { doc3: EX.doc2, class3: EX.class1, bag3: EX.bag2, member3: RDF::Node.new('ref3'), doc: EX.doc23 },
          { doc3: EX.doc3, class3: EX.class2, bag3: EX.bag3, member3: RDF::Node.new('ref1'), doc: EX.doc31 },
          { doc3: EX.doc3, class3: EX.class2, bag3: EX.bag3, member3: RDF::Node.new('ref2'), doc: EX.doc32 },
          { doc3: EX.doc3, class3: EX.class2, bag3: EX.bag3, member3: RDF::Node.new('ref3'), doc: EX.doc33 }
        ]
      end

      # From sp2b benchmark, query 7 bgp 1
      it "?class subclass document / ?doc type ?class / ?doc title ?title / ?bag2 ?member2 ?doc / ?doc2 refs ?bag2" do
        graph << [EX.class1, EX.subclass, EX.document]
        graph << [EX.class2, EX.subclass, EX.document]
        graph << [EX.class3, EX.subclass, EX.other]

        graph << [EX.doc1, EX.type, EX.class1]
        graph << [EX.doc2, EX.type, EX.class1]
        graph << [EX.doc3, EX.type, EX.class2]
        graph << [EX.doc4, EX.type, EX.class2]
        graph << [EX.doc5, EX.type, EX.class3]
        # no doc6 type

        graph << [EX.doc1, EX.title, EX.title1]
        graph << [EX.doc2, EX.title, EX.title2]
        graph << [EX.doc3, EX.title, EX.title3]
        graph << [EX.doc4, EX.title, EX.title4]
        graph << [EX.doc5, EX.title, EX.title5]
        graph << [EX.doc6, EX.title, EX.title6]

        graph << [EX.doc1, EX.refs, EX.bag1]
        graph << [EX.doc2, EX.refs, EX.bag2]
        graph << [EX.doc3, EX.refs, EX.bag3]
        graph << [EX.doc5, EX.refs, EX.bag5]

        graph << [EX.bag1, RDF::Node.new('ref1'), EX.doc11]
        graph << [EX.bag1, RDF::Node.new('ref2'), EX.doc12]
        graph << [EX.bag1, RDF::Node.new('ref3'), EX.doc13]

        graph << [EX.bag2, RDF::Node.new('ref1'), EX.doc21]
        graph << [EX.bag2, RDF::Node.new('ref2'), EX.doc22]
        graph << [EX.bag2, RDF::Node.new('ref3'), EX.doc23]

        graph << [EX.bag3, RDF::Node.new('ref1'), EX.doc31]
        graph << [EX.bag3, RDF::Node.new('ref2'), EX.doc32]
        graph << [EX.bag3, RDF::Node.new('ref3'), EX.doc33]

        graph << [EX.bag5, RDF::Node.new('ref1'), EX.doc51]
        graph << [EX.bag5, RDF::Node.new('ref2'), EX.doc52]
        graph << [EX.bag5, RDF::Node.new('ref3'), EX.doc53]

        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?class ex:subclass ex:document)
                 (triple ?doc ex:type ?class)
                 (triple ?doc ex:title ?title)
                 (triple ?doc ex:refs ?bag)
                 (triple ?bag ?member ?doc2)))))

        expect(query.execute(graph)).to have_result_set [
          { doc: EX.doc1, class: EX.class1, bag: EX.bag1,
            member: RDF::Node.new('ref1'), doc2: EX.doc11, title: EX.title1 },
          { doc: EX.doc1, class: EX.class1, bag: EX.bag1,
            member: RDF::Node.new('ref2'), doc2: EX.doc12, title: EX.title1 },
          { doc: EX.doc1, class: EX.class1, bag: EX.bag1,
            member: RDF::Node.new('ref3'), doc2: EX.doc13, title: EX.title1 },
          { doc: EX.doc2, class: EX.class1, bag: EX.bag2,
            member: RDF::Node.new('ref1'), doc2: EX.doc21, title: EX.title2 },
          { doc: EX.doc2, class: EX.class1, bag: EX.bag2,
            member: RDF::Node.new('ref2'), doc2: EX.doc22, title: EX.title2 },
          { doc: EX.doc2, class: EX.class1, bag: EX.bag2,
            member: RDF::Node.new('ref3'), doc2: EX.doc23, title: EX.title2 },
          { doc: EX.doc3, class: EX.class2, bag: EX.bag3,
            member: RDF::Node.new('ref1'), doc2: EX.doc31, title: EX.title3 },
          { doc: EX.doc3, class: EX.class2, bag: EX.bag3,
            member: RDF::Node.new('ref2'), doc2: EX.doc32, title: EX.title3 },
          { doc: EX.doc3, class: EX.class2, bag: EX.bag3,
            member: RDF::Node.new('ref3'), doc2: EX.doc33, title: EX.title3 },
        ]
      end

      it "?s1 p ?o1 / ?s2 p ?o2" do
        graph = RDF::Graph.new do |graph|
          graph << [EX.x1, EX.p, 1]
          graph << [EX.x2, EX.p, 2]
        end
        query = SPARQL::Algebra::Expression.parse(%q(
          (prefix ((ex: <http://example.org/>))
            (bgp (triple ?s1 ex:p ?o1)
                 (triple ?s2 ex:p ?o2)))))
        # Use set comparison for unordered compare on 1.8.7
        expect(query.execute(graph)).to have_result_set [
          {s1: EX.x1, o1: RDF::Literal(1), s2: EX.x1, o2: RDF::Literal(1)},
          {s1: EX.x1, o1: RDF::Literal(1), s2: EX.x2, o2: RDF::Literal(2)},
          {s1: EX.x2, o1: RDF::Literal(2), s2: EX.x1, o2: RDF::Literal(1)},
          {s1: EX.x2, o1: RDF::Literal(2), s2: EX.x2, o2: RDF::Literal(2)},
        ]
      end
    end
  end

  context "aggregates" do
    let(:graph) {
      RDF::Graph.new do |g|
        # simple patterns
        g << [EX.x1, EX.p, 1]
        g << [EX.x1, EX.p, 2]
        g << [EX.x1, EX.p, 3]
        g << [EX.x2, EX.p, 3]
      end
    }

    it "(count)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (count)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(4)}]
    end

    it "(count ?s)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (count ?s)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(4)}]
    end

    it "(count distinct ?s)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (count distinct ?s)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(2)}]
    end

    it "(sum ?o)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (sum ?o)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(9)}]
    end

    it "(sum distinct ?o)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (sum distinct ?o)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(6)}]
    end

    it "(min ?o)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (min ?o)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(1)}]
    end

    it "(min distinct ?o)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (min distinct ?o)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(1)}]
    end

    it "(max ?o)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (max ?o)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(3)}]
    end

    it "(max distinct ?o)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (max distinct ?o)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal(3)}]
    end

    it "(avg ?o)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (avg ?o)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal::Decimal.new(2.25)}]
    end

    it "(avg distinct ?o)" do
      query = SPARQL::Algebra::Expression.parse(%q(
      (project (?c)
       (extend ((?c ?.0))
         (group () ((?.0 (avg distinct ?o)))
           (bgp (triple ?s ?p ?o)))))))
      expect(query.execute(graph)).to have_result_set [{c: RDF::Literal::Decimal.new(2)}]
    end
  end

  context "in" do
    it "Finds value in literals" do
      expect(sparql_query(
        graphs: {
          default: {
            data: %q{
              @prefix rdf:        <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              _:a rdf:value 1 .
              _:a rdf:value 3 .
            },
            format: :ttl,
          }
        },
        query: %q{
          (prefix ((rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>))
            (project (?o)
              (filter (in ?o 0 1 2)
                (bgp (triple ?s ?p ?o)))))
        },
        sse: true
      )).to have_result_set [
        {o: RDF::Literal(1)},
      ]
    end

    it "Finds value in URIs" do
      expect(sparql_query(
        graphs: {
          default: {
            data: %q{
              @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
              @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
              _:a a rdf:Property .
              _:b a rdfs:Class .
              _:c a rdf:Datatype .
            },
            format: :ttl,
          }
        },
        query: %q{
          (prefix (
            (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
            (rdfs: <http://www.w3.org/2000/01/rdf-schema#>))
            (project (?o)
              (filter (in ?o rdf:Property rdfs:Class)
                (bgp (triple ?s ?p ?o)))))
        },
        sse: true
      )).to have_result_set [
        {o: RDF.Property},
        {o: RDF::RDFS.Class},
      ]
    end
  end

  context "join" do
    it "passes data/extracted-examples/query-4.1" do
      expect(sparql_query(
        graphs: {
          default: {
            data: %q{
              @prefix foaf:       <http://xmlns.com/foaf/0.1/> .
              @prefix rdf:        <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

              _:a  rdf:type        foaf:Person .
              _:a  foaf:name       "Alice" .
              _:a  foaf:mbox       <mailto:alice@example.com> .
              _:a  foaf:mbox       <mailto:alice@work.example> .

              _:b  rdf:type        foaf:Person .
              _:b  foaf:name       "Bob" .
            },
            format: :ttl,
          }
        },
        query: %q{
          (prefix ((foaf: <http://xmlns.com/foaf/0.1/>))
            (project (?name ?mbox)
              (join
                (bgp (triple ?x foaf:name ?name))
                (bgp (triple ?x foaf:mbox ?mbox)))))
        },
        sse: true
      )).to have_result_set [
        {name: RDF::Literal.new("Alice"), mbox: RDF::URI("mailto:alice@example.com")},
        {name: RDF::Literal.new("Alice"), mbox: RDF::URI("mailto:alice@work.example")},
      ]
    end

    it "parses" do
      query = %q(
          (join
            (bgp (triple :x :b ?a))
            (graph ?g2
              (bgp (triple :x :p ?x)))))

      expect(SPARQL::Algebra.parse(query)).to be_a(SPARQL::Algebra::Operator::Join)
    end
  end

  context "leftjoin" do
    it "passes data/examples/ex11.2.3.2_1" do
      expect(sparql_query(
        graphs: {
          default: {
            data: %q{
              @prefix foaf:        <http://xmlns.com/foaf/0.1/> .
              @prefix dc:          <http://purl.org/dc/elements/1.1/> .
              @prefix xs:          <http://www.w3.org/2001/XMLSchema#> .

              _:a  foaf:name       "Alice".

              _:b  foaf:givenName  "Bob" .
              _:b  dc:created      "2005-04-04T04:04:04Z"^^xs:dateTime .
            },
            format: :ttl
          }
        },
        query: %q{
          (prefix ((dc: <http://purl.org/dc/elements/1.1/>)
                   (foaf: <http://xmlns.com/foaf/0.1/>))
            (project (?name)
              (filter (! (bound ?created))
                (leftjoin
                  (bgp (triple ?x foaf:name ?name))
                  (bgp (triple ?x dc:created ?created))))))
        },
        sse: true
      )).to have_result_set [
        {name: RDF::Literal.new("Alice")},
      ]
    end

    it "passes data-r2/algebra/op-filter-1" do
      expect(sparql_query(
        graphs: {
          default: {
            data: %q{
              @prefix   :         <http://example/> .
              @prefix xsd:        <http://www.w3.org/2001/XMLSchema#> .

              :x1 :p "1"^^xsd:integer .
              :x2 :p "2"^^xsd:integer .

              :x3 :q "3"^^xsd:integer .
              :x3 :q "4"^^xsd:integer .
            },
            format: :ttl
          }
        },
        query: %q{
          (prefix ((: <http://example/>))
            (leftjoin
              (bgp (triple ?x :p ?v))
              (bgp (triple ?y :q ?w))
              (= ?v 2)))
        },
        sse: true
      )).to have_result_set [
        { 
            v: RDF::Literal.new('2' , datatype: RDF::URI('http://www.w3.org/2001/XMLSchema#integer')),
            w: RDF::Literal.new('4' , datatype: RDF::URI('http://www.w3.org/2001/XMLSchema#integer')),
            x: RDF::URI('http://example/x2'),
            y: RDF::URI('http://example/x3'),
        },
        { 
            v: RDF::Literal.new('2' , datatype: RDF::URI('http://www.w3.org/2001/XMLSchema#integer')),
            w: RDF::Literal.new('3' , datatype: RDF::URI('http://www.w3.org/2001/XMLSchema#integer')),
            x: RDF::URI('http://example/x2'),
            y: RDF::URI('http://example/x3'),
        },
        { 
            v: RDF::Literal.new('1' , datatype: RDF::URI('http://www.w3.org/2001/XMLSchema#integer')),
            x: RDF::URI('http://example/x1'),
        },
      ]
    end
  end

  context "union" do
    it "passes data/extracted-examples/query-6.1" do
      expect(sparql_query(
        graphs: {
          default: {
            data: %q{
              @prefix dc10:  <http://purl.org/dc/elements/1.0/> .
              @prefix dc11:  <http://purl.org/dc/elements/1.1/> .

              _:a  dc10:title     "SPARQL Query Language Tutorial" .

              _:b  dc11:title     "SPARQL Protocol Tutorial" .

              _:c  dc10:title     "SPARQL" .
              _:c  dc11:title     "SPARQL (updated)" .
            },
            format: :ttl
          }
        },
        query: %q{
          (prefix ((dc11: <http://purl.org/dc/elements/1.1/>)
                   (dc10: <http://purl.org/dc/elements/1.0/>))
            (project (?title)
              (union
                (bgp (triple ?book dc10:title ?title))
                (bgp (triple ?book dc11:title ?title)))))
        },
        sse: true
      )).to have_result_set [
        {title: RDF::Literal.new("SPARQL Query Language Tutorial")},
        {title: RDF::Literal.new("SPARQL Protocol Tutorial")},
        {title: RDF::Literal.new("SPARQL")},
        {title: RDF::Literal.new("SPARQL (updated)")},
      ]
    end
  end

  context "property paths" do
    let(:repo) {
      RDF::Repository.new << RDF::TriG::Reader.new(%(
        @prefix :      <http://example.org/> .
        @prefix ex:	<http://www.example.org/schema#>.
        @prefix in:	<http://www.example.org/instance#>.

        # data-diamond.ttl
        :a :p :b .
        :b :p :z .
        :a :p :c .
        :c :p :z .
        :b :q :B .
        :B :r :Z .

        <ng-01.ttl> {:a :p1 :b .}
        <ng-02.ttl> {:a :p1 :c .}
        <ng-03.ttl> {:a :p1 :d .}
      ))
    }

    {
      "path?" => {
        ":a (path? :p) ?v" => {
          query: %q{(prefix ((: <http://example.org/>)) (path :a (path? :p) ?v))},
          expected: [
            {v: RDF::URI("http://example.org/a")},
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
          ]
        },
        "?v (path? :p) :z" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?v (path? :p) :z))},
          expected: [
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
            {v: RDF::URI("http://example.org/z")},
          ]
        },
        "?x (path? :p) ?y" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?x (path? :p) ?y))},
          expected: [
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/a")},
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/b")},
            {x: RDF::URI("http://example.org/B"), y: RDF::URI("http://example.org/B")},
            {x: RDF::URI("http://example.org/c"), y: RDF::URI("http://example.org/c")},
            {x: RDF::URI("http://example.org/z"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/Z"), y: RDF::URI("http://example.org/Z")},
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/b")},
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/c")},
            {x: RDF::URI("http://example.org/c"), y: RDF::URI("http://example.org/z")},
          ]
        },
      },
      "path+" => {
        ":a (path+ :p) ?v" => {
          query: %q{(prefix ((: <http://example.org/>)) (path :a (path+ :p) ?v))},
          expected: [
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
            {v: RDF::URI("http://example.org/z")},
          ]
        },
        "?v (path+ :p) :z" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?v (path+ :p) :z))},
          expected: [
            {v: RDF::URI("http://example.org/a")},
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
          ]
        },
        "?x (path+ :p) ?y" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?x (path+ :p) ?y))},
          expected: [
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/b")},
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/c")},
            {x: RDF::URI("http://example.org/c"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/z")},
          ]
        },
      },
      "path*" => {
        ":a (path* :p) ?v" => {
          query: %q{(prefix ((: <http://example.org/>)) (path :a (path* :p) ?v))},
          expected: [
            {v: RDF::URI("http://example.org/a")},
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
            {v: RDF::URI("http://example.org/z")},
          ]
        },
        "?v (path* :p) :z" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?v (path* :p) :z))},
          expected: [
            {v: RDF::URI("http://example.org/a")},
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
            {v: RDF::URI("http://example.org/z")},
          ]
        },
        "?x (path* :p) ?y" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?x (path* :p) ?y))},
          expected: [
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/a")},
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/b")},
            {x: RDF::URI("http://example.org/B"), y: RDF::URI("http://example.org/B")},
            {x: RDF::URI("http://example.org/c"), y: RDF::URI("http://example.org/c")},
            {x: RDF::URI("http://example.org/z"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/Z"), y: RDF::URI("http://example.org/Z")},
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/b")},
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/c")},
            {x: RDF::URI("http://example.org/c"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/z")},
          ]
        },
      },
      "alt" => {
        ":b (alt :p :q) ?v" => {
          query: %q{(prefix ((: <http://example.org/>)) (path :b (alt :p :q) ?v))},
          expected: [
            {v: RDF::URI("http://example.org/z")},
            {v: RDF::URI("http://example.org/B")},
          ]
        },
        "?v (alt :p :q) :z" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?v (alt :p :q) :z))},
          expected: [
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
          ]
        },
        "?x (alt :p :q) ?y" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?x (alt :p :q) ?y))},
          expected: [
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/b")},
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/c")},
            {x: RDF::URI("http://example.org/c"), y: RDF::URI("http://example.org/z")},
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/B")},
          ]
        },
      },
      "seq" => {
        ":b (seq :p :q) ?v" => {
          query: %q{(prefix ((: <http://example.org/>)) (path :a (seq :p :q) ?v))},
          expected: [
            {v: RDF::URI("http://example.org/B")},
          ]
        },
        "?v (seq :p :q) :z" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?v (seq :p :q) :B))},
          expected: [
            {v: RDF::URI("http://example.org/a")},
          ]
        },
        "?x (seq :p :q) ?y" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?x (seq :p :q) ?y))},
          expected: [
            {x: RDF::URI("http://example.org/a"), y: RDF::URI("http://example.org/B")},
          ]
        },
      },
      "reverse" => {
        ":z (reverse :p) ?v" => {
          query: %q{(prefix ((: <http://example.org/>)) (path :z (reverse :p) ?v))},
          expected: [
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
          ]
        },
        "?v (reverse :p) :z" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?v (reverse :p) :a))},
          expected: [
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
          ]
        },
        "?x (reverse :p) ?y" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?x (reverse :p) ?y))},
          expected: [
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/a")},
            {x: RDF::URI("http://example.org/c"), y: RDF::URI("http://example.org/a")},
            {x: RDF::URI("http://example.org/z"), y: RDF::URI("http://example.org/b")},
            {x: RDF::URI("http://example.org/z"), y: RDF::URI("http://example.org/c")},
          ]
        },
      },
      "notoneof" => {
        ":b (notoneof :p) ?v" => {
          query: %q{(prefix ((: <http://example.org/>)) (path :b (notoneof :p) ?v))},
          expected: [
            {v: RDF::URI("http://example.org/B")},
          ]
        },
        "?v (notoneof :q) :z" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?v (notoneof :q) :z))},
          expected: [
            {v: RDF::URI("http://example.org/b")},
            {v: RDF::URI("http://example.org/c")},
          ]
        },
        "?x (notoneof :p) ?y" => {
          query: %q{(prefix ((: <http://example.org/>)) (path ?x (notoneof :p) ?y))},
          expected: [
            {x: RDF::URI("http://example.org/b"), y: RDF::URI("http://example.org/B")},
            {x: RDF::URI("http://example.org/B"), y: RDF::URI("http://example.org/Z")},
          ]
        },
      }
    }.each do |name, tests|
      describe name do
        tests.each do |tname, opts|
          it tname do
            if opts[:error]
              expect {sparql_query({sse: true, graphs: repo}.merge(opts))}.to raise_error(opts[:error])
            else
              expected = opts[:expected]
              actual = sparql_query({sse: true, graphs: repo}.merge(opts))
              expect(actual).to have_result_set expected
              expect(actual.length).to produce(expected.length, [{actual: actual.map(&:to_h), expected: expected.map(&:to_h)}.to_sse])
            end
          end
        end
      end
    end

    describe "sequence" do
      let(:repo) {
        RDF::Repository.new << RDF::TriG::Reader.new(%(
          @prefix :      <http://example.org/> .

          :a :b (
            [:p [:p [:q 123]]]
            [:r "hello"]
          ) .

          :a1 :b1 (
            [:p [:p [:q 1234]]]
            [:r "hello"]
          ) .

          :a2 :b2 (
            [:p [:p [:q 123]]]
            [:r "goodby"]
          ) .
        ))
      }

      it "finds collection sequence" do
        query = %((prefix
                   ((: <http://example.org/>) (rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>))
                   (sequence
                    (bgp
                     (triple ?s ?p ??0)
                     (triple ??0 rdf:first ??1)
                     (triple ??0 rdf:rest ??3)
                     (triple ??3 rdf:first ??2)
                     (triple ??3 rdf:rest rdf:nil))
                    (path ??1 (seq (path* :p) :q) 123)
                    (path ??2 (path? :r) "hello")) ))

        #require 'pry'; binding.pry
        actual = sparql_query({query: query, sse: true, graphs: repo})
        expect(actual.length).to eql 1
        solution = actual.first
        expect(solution[:s]).to eql RDF::URI("http://example.org/a")
        expect(solution[:p]).to eql RDF::URI("http://example.org/b")
      end
    end
  end

  context "query forms" do
    {
      # @see http://www.w3.org/TR/sparql11-query/#QSynIRI
      %q((base <http://example.org/>
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Base.new(
          RDF::URI("http://example.org/"),
          RDF::Query.new {pattern [RDF::URI("http://example.org/a"), RDF::URI("http://example.org/b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#modDistinct
      %q((distinct
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Distinct.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#evaluation
      %q((exprlist (< ?x 1))) =>
        Operator::Exprlist.new(
          Operator::LessThan.new(Variable("x"), RDF::Literal.new(1))),
      %q((exprlist (< ?x 1) (> ?y 1))) =>
        Operator::Exprlist.new(
          Operator::LessThan.new(Variable("x"), RDF::Literal.new(1)),
          Operator::GreaterThan.new(Variable("y"), RDF::Literal.new(1))),

      # @see http://www.w3.org/TR/sparql11-query/#evaluation
      %q((filter
          (< ?x 1)
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Filter.new(
          Operator::LessThan.new(Variable("x"), RDF::Literal.new(1)),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      %q((filter
          (exprlist
            (< ?x 1)
            (> ?y 1))
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Filter.new(
          Operator::Exprlist.new(
            Operator::LessThan.new(Variable("x"), RDF::Literal.new(1)),
            Operator::GreaterThan.new(Variable("y"), RDF::Literal.new(1))),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#ebv
      %q((filter ?x
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Filter.new(
          Variable("x"),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),
      %q((filter
          (= ?x <a>)
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Filter.new(
          Operator::Equal.new(Variable("x"), RDF::URI("a")),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#namedAndDefaultGraph
      %q((graph ?g
          (bgp  (triple <a> <b> 123.0)))) =>
        Operator::Graph.new(
          Variable("g"),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      %q((join
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0)))) =>
        Operator::Join.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      %q((leftjoin
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0)))) =>
        Operator::LeftJoin.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]}),
      %q((leftjoin
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0))
          (bound ?x))) =>
        Operator::LeftJoin.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]},
          Operator::Bound.new(Variable("x"))),

      # @see http://www.w3.org/TR/sparql11-query/#modOrderBy
      %q((order (<a>)
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [RDF::URI("a")],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),
      %q((order (<a> <b>)
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [RDF::URI("a"), RDF::URI("b")],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),
      %q((order ((asc 1))
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [Operator::Asc.new(RDF::Literal.new(1))],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),
      %q((order ((desc ?a))
          (bgp (triple <a> <b> ?a)))) =>
        Operator::Order.new(
          [Operator::Desc.new(Variable("a"))],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("a")]}),
      %q((order (?a ?b ?c)
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [Variable(?a), Variable(?b), Variable(?c)],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),
      %q((order (?a (asc 1) (isIRI <b>))
          (bgp (triple <a> <b> ?o)))) =>
        Operator::Order.new(
          [Variable(?a), Operator::Asc.new(RDF::Literal.new(1)), Operator::IsIRI.new(RDF::URI("b"))],
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), Variable("o")]}),

      # @see http://www.w3.org/TR/sparql11-query/#QSynIRI
      %q((prefix ((ex: <http://example.org/>))
          (bgp (triple ?s ex:p1 123.0)))) =>
        Operator::Prefix.new(
          [[:"ex:", RDF::URI("http://example.org/")]],
          RDF::Query.new {pattern [RDF::Query::Variable.new("s"), EX.p1, RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#modProjection
      %q((project (?s)
          (bgp (triple ?s <p> 123.0)))) =>
        Operator::Project.new(
          [Variable("s")],
          RDF::Query.new {pattern [Variable("s"), RDF::URI("p"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#modReduced
      %q((reduced
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Reduced.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),

      # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebraEval
      %q((slice _ 100
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Slice.new(
          :_, RDF::Literal.new(100),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),
      %q((slice 1 2
          (bgp (triple <a> <b> 123.0)))) =>
        Operator::Slice.new(
          RDF::Literal.new(1), RDF::Literal.new(2),
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]}),


      # @see http://www.w3.org/TR/sparql11-query/#sparqlTriplePatterns
      %q((triple <a> <b> <c>)) => RDF::Query::Pattern.new(RDF::URI("a"), RDF::URI("b"), RDF::URI("c")),
      %q((triple ?a _:b "c")) => RDF::Query::Pattern.new(RDF::Query::Variable.new("a"), RDF::Node.new("b"), RDF::Literal.new("c")),

      # @see http://www.w3.org/TR/sparql11-query/#sparqlBasicGraphPatterns
      %q((bgp (triple <a> <b> <c>))) => RDF::Query.new { pattern [RDF::URI("a"), RDF::URI("b"), RDF::URI("c")]},

      # @see http://www.w3.org/TR/sparql11-query/#sparqlAlgebra
      %q((union
          (bgp (triple <a> <b> 123.0))
          (bgp (triple <a> <b> 456.0)))) =>
        Operator::Union.new(
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(123.0)]},
          RDF::Query.new {pattern [RDF::URI("a"), RDF::URI("b"), RDF::Literal.new(456.0)]}),
    }.each_pair do |sse, operator|
      it "generates SSE for #{sse}" do
        expect(SXP::Reader::SPARQL.read(sse)).to eq operator.to_sxp_bin
      end

      it "parses SSE for #{sse}" do
        expect(SPARQL::Algebra::Expression.parse(sse)).to eq operator
      end
    end
  end

  context "datasets" do
    it "loads FROM graph as default graph" do
      queryable = RDF::Repository.new
      expect(queryable).to receive(:load).with("data-g1.ttl",
        {
          base_uri: RDF::URI.new("data-g1.ttl"),
          graph_name: RDF::URI.new("data-g1.ttl"),
          debug: kind_of(Object)
        })
      query = SPARQL::Algebra::Expression.parse(%q((dataset (<data-g1.ttl>) (bgp))))
      query.execute(queryable)
    end

    it "loads FROM NAMED graph as named graph" do
      queryable = RDF::Repository.new
      expect(queryable).to receive(:load).with("data-g1.ttl", {
        graph_name: RDF::URI("data-g1.ttl"),
        base_uri: RDF::URI("data-g1.ttl"),
        debug: kind_of(Object)
      })
      query = SPARQL::Algebra::Expression.parse(%q((dataset ((named <data-g1.ttl>)) (bgp))))
      query.execute(queryable)
    end

    it "raises error when loading into an immutable queryable" do
      queryable = RDF::Graph.new
      expect(queryable).to receive(:immutable?).and_return(true)
      query = SPARQL::Algebra::Expression.parse(%q((dataset (<data-g1.ttl>) (bgp))))
      expect {query.execute(queryable)}.to raise_error(TypeError)
    end
  end

  context "odd test cases" do
    it "executes RDFa Test Case 0279" do
      ttl = %(
      @base <http://127.0.0.1:9393/test-suite/test-cases/rdfa1.1/html5/0279.html> .
      @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
      @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

      <> rdf:value "2012-03-18T00:00:00Z"^^xsd:string .
      )
      sse = %(
        (prefix ((rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>)
                 (xsd: <http://www.w3.org/2001/XMLSchema#>))
          (ask (bgp (triple ??0 rdf:value "2012-03-18T00:00:00Z"^^xsd:string)))
        )
      )
      queryable = RDF::Repository.new << RDF::Turtle::Reader.new(ttl)
      query = SPARQL::Algebra::Expression.parse(sse)
      expect(query.execute(queryable)).to eq RDF::Literal::TRUE
    end
  end

  context "untyped literal => xsd:string changes" do
    {
      "open-eq-07" => [
        "data-r2/open-world/open-eq-07.sse",
        "http://www.w3.org/2001/sw/DataAccess/tests/data-r2/open-world/data-2.ttl",
        %q{
          <sparql
              xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
              xmlns:xs="http://www.w3.org/2001/XMLSchema#"
              xmlns="http://www.w3.org/2005/sparql-results#" >
            <head>
              <variable name="x1"/>
              <variable name="v1"/>
              <variable name="x2"/>
              <variable name="v2"/>
            </head>
            <results>
              <result>
                <binding name="x1">
                  <uri>http://example/x1</uri>
                </binding>
                <binding name="v1">
                  <literal>xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x1</uri>
                </binding>
                <binding name="v2">
                  <literal>xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x1</uri>
                </binding>
                <binding name="v1">
                  <literal>xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x4</uri>
                </binding>
                <binding name="v2">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#string">xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x2</uri>
                </binding>
                <binding name="v1">
                  <literal xml:lang="en">xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x2</uri>
                </binding>
                <binding name="v2">
                  <literal xml:lang="en">xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x2</uri>
                </binding>
                <binding name="v1">
                  <literal xml:lang="en">xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x3</uri>
                </binding>
                <binding name="v2">
                  <literal xml:lang="EN">xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x3</uri>
                </binding>
                <binding name="v1">
                  <literal xml:lang="EN">xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x2</uri>
                </binding>
                <binding name="v2">
                  <literal xml:lang="en">xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x3</uri>
                </binding>
                <binding name="v1">
                  <literal xml:lang="EN">xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x3</uri>
                </binding>
                <binding name="v2">
                  <literal xml:lang="EN">xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x4</uri>
                </binding>
                <binding name="v1">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#string">xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x1</uri>
                </binding>
                <binding name="v2">
                  <literal>xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x4</uri>
                </binding>
                <binding name="v1">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#string">xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x4</uri>
                </binding>
                <binding name="v2">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#string">xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x5</uri>
                </binding>
                <binding name="v1">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#integer">xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x5</uri>
                </binding>
                <binding name="v2">
                  <literal datatype="http://www.w3.org/2001/XMLSchema#integer">xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x6</uri>
                </binding>
                <binding name="v1">
                  <literal datatype="http://example/unknown">xyz</literal>
                </binding>
                <binding name="x2">
                  <uri>http://example/x6</uri>
                </binding>
                <binding name="v2">
                  <literal datatype="http://example/unknown">xyz</literal>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x7</uri>
                </binding>
                <binding name="v1">
                  <bnode>b0</bnode>
                </binding>
                <binding name="x2">
                  <uri>http://example/x7</uri>
                </binding>
                <binding name="v2">
                  <bnode>b0</bnode>
                </binding>
              </result>
              <result>
                <binding name="x1">
                  <uri>http://example/x8</uri>
                </binding>
                <binding name="v1">
                  <uri>http://example/xyz</uri>
                </binding>
                <binding name="x2">
                  <uri>http://example/x8</uri>
                </binding>
                <binding name="v2">
                  <uri>http://example/xyz</uri>
                </binding>
              </result>
            </results>
          </sparql>
        },
      ],
      "open-eq-08" => [
        "data-r2/open-world/open-eq-08.sse",
        "http://www.w3.org/2001/sw/DataAccess/tests/data-r2/open-world/data-2.ttl",
        %q{}
      ],
      "open-eq-10" => [
        "data-r2/open-world/open-eq-10.sse",
        "http://www.w3.org/2001/sw/DataAccess/tests/data-r2/open-world/data-2.ttl",
        %q{}
      ],
      "open-eq-11" => [
        "data-r2/open-world/open-eq-11.sse",
        "http://www.w3.org/2001/sw/DataAccess/tests/data-r2/open-world/data-2.ttl",
        %q{}
      ],
      "Strings: Distinct" => [
        "data-r2/distinct/distinct-1.sse",
        "http://www.w3.org/2001/sw/DataAccess/tests/data-r2/distinct/data-str.ttl",
        %q{}
      ],
      "All: Distinct" => [
        "data-r2/distinct/distinct-1.sse",
        "http://www.w3.org/2001/sw/DataAccess/tests/data-r2/distinct/data-all.ttl",
        %q{}
      ],
      }.each do |test, (query_path, data, result)|
      it "describes #{test}" do
        skip "Make this example work"
        #query = IO.read(File.expand_path(File.join(File.dirname(__FILE__), "..", "dawg", query_path)))
        #solutions = SPARQL::Client.parse_xml_bindings(result)

        #sparql_query(
        #  form: :describe, sse: true,
        #  graphs: {default: {data: data, format: :ttl}},
        #  query: query).should == solutions
      end
    end
  end
end
