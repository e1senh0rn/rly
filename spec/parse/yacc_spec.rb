require "rly"
require "rly/parse/grammar"

describe Rly::Yacc do
  it "accepts a set of rules" do
    expect {
      Class.new(Rly::Yacc) do
        rule 'statement : expression' do |e|
          @val = e
        end
      end
    }.to_not raise_error
  end

  it "accepts an instance of lexer as an argument" do
    testParser = Class.new(Rly::Yacc) do
      rule 'statement : VALUE' do |v|
        @val = v
      end
    end

    testLexer = Class.new(Rly::Lex) do
      token :VALUE, /[a-z]+/
    end
    m = testLexer.new

    p = testParser.new(m)
    expect(p.lex).to eq(m)
  end

  it "can use built in lexer if one is defined" do
    testParser = Class.new(Rly::Yacc) do
      lexer do
        token :VALUE, /[a-z]+/
      end

      rule 'statement : VALUE' do |v|
        @val = v
      end
    end

    p = testParser.new
    expect(p.lex).to be_kind_of(Rly::Lex)
  end

  it "raises error if no lexer is built in and no given" do
    testParser = Class.new(Rly::Yacc) do
      rule 'statement : VALUE' do |v|
        @val = v
      end
    end

    expect { testParser.new }.to raise_error(ArgumentError)
  end
end
