require "rly"
require "rly/parse/grammar"
require "rly/parse/ply_dump"

describe Rly::Grammar do
  it "requires a list of terminals to be initialized" do
    grammar = Rly::Grammar.new([:NUMBER])
    expect(grammar.terminals[:NUMBER]).to_not be_nil
  end

  it "rejects terminals named in lowercase" do
    expect { Rly::Grammar.new([:test]) } .to raise_error(ArgumentError)
  end

  it "has a default terminal -- error" do
    grammar = Rly::Grammar.new([])
    expect(grammar.terminals[:error]).to_not be_nil
  end

  context "Precedence specs" do
    let(:grammar) { Rly::Grammar.new([]) }

    it "allows to set precedence" do
      expect { grammar.set_precedence('+', :left, 1) }.to_not raise_error
    end

    it "does not allow to set precedence after any productions have been added" do
      grammar.add_production(:expression, [:expression, '+', :expression])
      expect { grammar.set_precedence('+', :left, 1) } .to raise_error(RuntimeError)
    end

    it "does not allow setting precedence several times for same terminal" do
      grammar.set_precedence('+', :left, 1)
      expect { grammar.set_precedence('+', :left, 1) } .to raise_error(ArgumentError)
    end

    it "allows setting only :left, :right or :noassoc precedence associations" do
      expect { grammar.set_precedence('+', :bad, 1) } .to raise_error(ArgumentError)
    end
  end

  context "Production specs" do
    let(:grammar) { Rly::Grammar.new([]) }

    it "returns a Production object when adding production" do
      p = grammar.add_production(:expression, [:expression, '+', :expression])
      expect(p).to be_a(Rly::Production)
    end

    it "rejects productions not named in lowercase" do
      expect { grammar.add_production(:BAD, []) } .to raise_error(ArgumentError)
    end

    it "rejects production named :error" do
      expect { grammar.add_production(:error, []) } .to raise_error(ArgumentError)
    end

    it "registers one-char terminals" do
      grammar.add_production(:expression, [:expression, '+', :expression])
      expect(grammar.terminals['+']).to_not be_nil
    end

    it "raises ArgumentError if one-char terminal is not actually an one char" do
      expect { grammar.add_production(:expression, [:expression, 'lulz', :expression]) } .to raise_error(ArgumentError)
    end

    it "calculates production precedence based on rightmost terminal" do
      grammar.set_precedence('+', :left, 1)
      p = grammar.add_production(:expression, [:expression, '+', :expression])
      expect(p.precedence).to eq([:left, 1])
    end

    it "defaults precedence to [:right, 0]" do
      p = grammar.add_production(:expression, [:expression, '+', :expression])
      expect(p.precedence).to eq([:right, 0])
    end

    it "adds production to the list of productions" do
      p = grammar.add_production(:expression, [:expression, '+', :expression])
      expect(grammar.productions.count).to eq(2)
      grammar.productions.last == p
    end

    it "adds production to the list of productions referenced by names" do
      p = grammar.add_production(:expression, [:expression, '+', :expression])
      expect(grammar.prodnames.count).to eq(1)
      expect(grammar.prodnames[:expression]).to eq([p])
    end

    it "adds production to the list of non-terminals" do
      grammar.add_production(:expression, [:expression, '+', :expression])
      expect(grammar.nonterminals[:expression]).to_not be_nil
    end

    it "adds production number to referenced terminals" do
      p = grammar.add_production(:expression, [:expression, '+', :expression])
      expect(grammar.terminals['+']).to eq([p.index])
    end

    it "adds production number to referenced non-terminals" do
      p = grammar.add_production(:expression, [:expression, '+', :expression])
      expect(grammar.nonterminals[:expression]).to eq([p.index, p.index])
    end

    it "does not allow duplicate rules" do
      grammar.add_production(:expression, [:expression, '+', :expression])
      expect { grammar.add_production(:expression, [:expression, '+', :expression]) } .to raise_error(ArgumentError)
    end
  end

  context "Start symbol specs" do
    let(:grammar) do
      Rly::Grammar.new([]).tap do |g|
        g.add_production(:expression, [:expression, '+', :expression])
        g.set_start
      end
    end

    it "sets start symbol if it is specified explicitly" do
      expect(grammar.start).to eq(:expression)
    end

    it "sets start symbol based on first production if it is not specified explicitly" do
      expect(grammar.start).to eq(:expression)
    end

    it "accepts only existing non-terminal as a start" do
      g = Rly::Grammar.new([:NUMBER])
      g.add_production(:expression, [:expression, '+', :expression])
      expect { g.set_start(:NUMBER) } .to raise_error(ArgumentError)
      expect { g.set_start(:new_sym) } .to raise_error(ArgumentError)
    end

    it "sets zero rule to :S' -> :start" do
      production = grammar.productions[0]
      expect(production.index).to eq(0)
      expect(production.name).to eq(:"S'")
      expect(production.prod).to eq([:expression])
    end

    it "adds 0 to start rule nonterminals" do
      expect(grammar.nonterminals[:expression][-1]).to eq(0)
    end
  end

  context "LR table generation specs" do
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

    it "builds LR items for grammar" do
      expect(grammar.productions.length).to eq(5)
      items = [2, 2, 4, 4, 2]
      grammar.productions.each_with_index do |p, i|
        expect(p.lr_items.count).to eq(items[i])
      end
    end

    it "sets LR items to correct default values" do
      i = grammar.productions[0].lr_items[0]
      expect(i.lr_after).to eq([grammar.productions[1]])
      expect(i.prod).to eq([:'.', :statement])

      i = grammar.productions[0].lr_items[1]
      expect(i.lr_after).to eq([])
      expect(i.prod).to eq([:statement, :'.'])

      i = grammar.productions[2].lr_items[0]
      expect(i.lr_after).to eq(grammar.productions[2..4])
      expect(i.prod).to eq([:'.', :expression, '+', :expression])
    end

    it "builds correct FIRST table" do
      first = grammar.compute_first
      expect(first).to eq(
        :'$end' => [:'$end'],
        '+' => ['+'],
        '-' => ['-'],
        NUMBER: [:NUMBER],
        error: [:error],
        expression: [:NUMBER],
        statement: [:NUMBER]
      )
    end

    it "builds correct FOLLOW table" do
      grammar.compute_first
      follow = grammar.compute_follow
      expect(follow).to eq(expression: [:'$end', '+', '-'], statement: [:'$end'])
    end
  end

  it "should generate parser.out same as Ply does" do
    pending "thx to python dicts we have a different order of states. ideas?"
    g = Rly::Grammar.new([:NUMBER])

    g.set_precedence('+', :left, 1)
    g.set_precedence('-', :left, 1)

    g.add_production(:statement, [:expression])
    g.add_production(:expression, [:expression, '+', :expression])
    g.add_production(:expression, [:expression, '-', :expression])
    g.add_production(:expression, [:NUMBER])

    g.set_start

    d = Rly::PlyDump.new(g)
    orig = file_fixture("minicalc_ply_parser.out").read
    expect(d.to_s).to eq(orig)
  end
end
