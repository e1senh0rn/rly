require "rly"
require "rly/parse/grammar"

describe Rly::Yacc do
  it "accepts a set of rules" do
    expect do
      Class.new(Rly::Yacc) do
        rule 'statement : expression' do |e|
          @val = e
        end
      end
    end.to_not raise_error
  end

  it "accepts an instance of lexer as an argument" do
    test_parser = Class.new(Rly::Yacc) do
      rule 'statement : VALUE' do |v|
        @val = v
      end
    end

    test_lexer = Class.new(Rly::Lex) do
      token :VALUE, /[a-z]+/
    end
    m = test_lexer.new

    p = test_parser.new(m)
    expect(p.lex).to eq(m)
  end

  it "can use built in lexer if one is defined" do
    test_parser = Class.new(Rly::Yacc) do
      lexer do
        token :VALUE, /[a-z]+/
      end

      rule 'statement : VALUE' do |v|
        @val = v
      end
    end

    p = test_parser.new
    expect(p.lex).to be_kind_of(Rly::Lex)
  end

  it "raises error if no lexer is built in and no given" do
    test_parser = Class.new(Rly::Yacc) do
      rule 'statement : VALUE' do |v|
        @val = v
      end
    end

    expect { test_parser.new }.to raise_error(ArgumentError)
  end
end
