require "rly"
require "rly/parse/grammar"
require "rly/parse/lr_table"

describe Rly::LRTable do
  let(:grammar) do
    Rly::Grammar.new([:NUMBER]).tap do |g|
      g.set_precedence('+', :left, 1)
      g.set_precedence('-', :left, 1)

      g.add_production(:statement, [:expression])
      g.add_production(:expression, [:expression, '+', :expression])
      g.add_production(:expression, [:expression, '-', :expression])
      g.add_production(:expression, [:NUMBER])

      g.set_start

      g.build_lritems
    end
  end

  let(:table) { Rly::LRTable.new(grammar) }
  let(:lr0_items) { table.send(:lr0_items) }
  let(:nullable) { table.send :compute_nullable_nonterminals }
  let(:transitions) { table.send(:find_nonterminal_transitions, lr0_items) }

  it "computes the LR(0) closure operation on I, where I is a set of LR(0) items" do
    lr0_c = table.send(:lr0_closure, [grammar.productions[0].lr_next])
    expect(lr0_c.length).to eq(5)

    lr0_c.length.times do |i|
      expect(lr0_c[i]).to eq(grammar.productions[i].lr_next)
    end
  end

  it "computes the LR(0) goto function goto(I,X) where I is a set of LR(0) items and X is a grammar symbol" do
    lr0_c = table.send(:lr0_closure, [grammar.productions[0].lr_next])
    lr0_g = table.send(:lr0_goto, lr0_c, :statement)

    expect(lr0_g.length).to eq(1)
    expect(lr0_g[0].name).to eq(:"S'")
    expect(lr0_g[0].prod).to eq([:statement, :'.'])

    lr0_g = table.send(:lr0_goto, lr0_c, :expression)

    expect(lr0_g.length).to eq(3)
    expect(lr0_g[0].name).to eq(:statement)
    expect(lr0_g[0].prod).to eq([:expression, :'.'])
    expect(lr0_g[1].name).to eq(:expression)
    expect(lr0_g[1].prod).to eq([:expression, :'.', '+', :expression])
    expect(lr0_g[2].name).to eq(:expression)
    expect(lr0_g[2].prod).to eq([:expression, :'.', '-', :expression])
  end

  it "computes the LR(0) sets of item function" do
    reflist = [
      "S' -> . statement|statement -> . expression|expression -> . expression + expression|expression -> . expression - expression|expression -> . NUMBER",
      "S' -> statement .",
      "statement -> expression .|expression -> expression . + expression|expression -> expression . - expression",
      "expression -> NUMBER .",
      "expression -> expression + . expression|expression -> . expression + expression|expression -> . expression - expression|expression -> . NUMBER",
      "expression -> expression - . expression|expression -> . expression + expression|expression -> . expression - expression|expression -> . NUMBER",
      "expression -> expression + expression .|expression -> expression . + expression|expression -> expression . - expression",
      "expression -> expression - expression .|expression -> expression . + expression|expression -> expression . - expression"
    ]

    expect(lr0_items.length).to eq(reflist.length)
    expect(lr0_items.map { |a| a.map { |k| k.to_s } .join('|') }).to eq(reflist)
  end

  it "creates a dictionary containing all of the non-terminals that might produce an empty production" do
    # TODO: write a better spec
    expect(nullable).to eq({})
  end

  it "finds all of the non-terminal transitions" do
    expect(transitions).to eq([
      [0, :statement],
      [0, :expression],
      [4, :expression],
      [5, :expression]
    ])
  end

  it "computes the DR(p,A) relationships for non-terminal transitions" do
    expect(table.send :dr_relation, lr0_items, transitions[0], nullable).to eq([:'$end'])
    expect(table.send :dr_relation, lr0_items, transitions[1], nullable).to eq(['+', '-'])
  end

  it "computes the READS() relation (p,A) READS (t,C)" do
    # TODO: write a better spec
    expect(table.send :reads_relation, lr0_items, transitions[0], nullable).to eq([])
    expect(table.send :reads_relation, lr0_items, transitions[1], nullable).to eq([])
  end

  it "computes the read sets given a set of LR(0) items" do
    result = table.send(:compute_read_sets, lr0_items, transitions, nullable)

    expect(result).to eq({
      [0, :statement]  => [:'$end'],
      [5, :expression] => ['+', '-'],
      [4, :expression] => ['+', '-'],
      [0, :expression] => ['+', '-']
    })
  end

  it "determines the lookback and includes relations" do
    lookd, included = table.send(:compute_lookback_includes, lr0_items, transitions, nullable)

    expect(included).to eq({
      [5, :expression] => [ [0, :expression], [4, :expression], [5, :expression], [5, :expression] ],
      [4, :expression] => [ [0, :expression], [4, :expression], [4, :expression], [5, :expression] ],
      [0, :expression] => [ [0, :statement] ]
    })

    lookd = lookd.each_with_object({}) { |(k, v), h| h[k] = v.map { |n,i| [n, i.to_s] } }

    # NOTE: this one goes not map 1-1 to pry as we have differences in lr0_items order. Looks valid though.
    expected = {
      [0, :statement] => [ [2, "statement -> expression ."] ],
      [0, :expression]=> [
        [6, "expression -> expression + expression ."],
        [6, "expression -> expression . + expression"],
        [6, "expression -> expression . - expression"],
        [7, "expression -> expression - expression ."],
        [7, "expression -> expression . + expression"],
        [7, "expression -> expression . - expression"],
        [3, "expression -> NUMBER ."]
      ],
      [4, :expression] => [
      [6, "expression -> expression + expression ."],
        [6, "expression -> expression . + expression"],
        [6, "expression -> expression . - expression"],
        [7, "expression -> expression - expression ."],
        [7, "expression -> expression . + expression"],
        [7, "expression -> expression . - expression"],
        [3, "expression -> NUMBER ."]
      ],
      [5, :expression] => [
        [6, "expression -> expression + expression ."],
        [6, "expression -> expression . + expression"],
        [6, "expression -> expression . - expression"],
        [7, "expression -> expression - expression ."],
        [7, "expression -> expression . + expression"],
        [7, "expression -> expression . - expression"],
        [3, "expression -> NUMBER ."]
      ]}

    expect(lookd).to eq(expected)
  end

  it "computes the follow sets given a set of LR(0) items, a set of non-terminal transitions, a readset, and an include set" do
    readsets = table.send(:compute_read_sets, lr0_items, transitions, nullable)
    _, included = table.send(:compute_lookback_includes, lr0_items, transitions, nullable)

    followsets = table.send(:compute_follow_sets, transitions, readsets, included)
    expect(followsets).to eq({
      [0, :statement] => [:'$end'],
      [5, :expression] => ['+', '-', :'$end'],
      [4, :expression] => ['+', '-', :'$end'],
      [0, :expression] => ['+', '-', :'$end']
    })
  end

  it "attaches the lookahead symbols to grammar rules" do
    skip "verify that values in LRItem#lookaheads are meaningful"
    readsets = table.send(:compute_read_sets, lr0_items, transitions, nullable)
    lookd, included = table.send(:compute_lookback_includes, lr0_items, transitions, nullable)
    followsets = table.send(:compute_follow_sets, transitions, readsets, included)

    result = table.send(:add_lookaheads, lookd, followsets)
  end

  it "parses the table" do
    expect { table.parse_table } .to_not raise_error
  end
end
