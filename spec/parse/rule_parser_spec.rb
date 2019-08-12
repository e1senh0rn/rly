require "rly"
require "rly/parse/rule_parser"

describe Rly::RuleParser do
  it "parses a simple rule string" do
    s = 'expression : expression "+" expression
                    | expression "-" expression
                    | expression "*" expression
                    | expression "/" expression'
    p = Rly::RuleParser.new

    productions = p.parse(s)

    expect(productions.length).to eq(4)
    expect(productions[0]).to eq([:expression, [:expression, '+', :expression], nil])
    expect(productions[1]).to eq([:expression, [:expression, '-', :expression], nil])
    expect(productions[2]).to eq([:expression, [:expression, '*', :expression], nil])
    expect(productions[3]).to eq([:expression, [:expression, '/', :expression], nil])
  end

  it "tokenizes the rule correctly" do
    s = 'maybe_superclasses : ":" superclasses |'
    l = Rly::RuleParser.lexer_class.new(s)

    expect(l.next.type).to eq(:ID)
    expect(l.next.type).to eq(':')
    expect(l.next.type).to eq(:LITERAL)
    expect(l.next.type).to eq(:ID)
    expect(l.next.type).to eq('|')
  end
end
