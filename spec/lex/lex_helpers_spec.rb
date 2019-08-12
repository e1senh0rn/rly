require "rly"
require "rly/helpers"

describe "Rly::Lex Helpers" do
  it "has a helper to use a common whitespace ignore pattern" do
    test_lexer = Class.new(Rly::Lex) do
      ignore_spaces_and_tabs
    end

    expect { test_lexer.new(" \t \t").next }.to_not raise_exception
  end

  it "has a helper to parse numeric tokens" do
    test_lexer = Class.new(Rly::Lex) do
      lex_number_tokens
    end

    tok = test_lexer.new("123").next
    expect(tok.type).to eq(:NUMBER)
    expect(tok.value).to eq(123)
  end

  it "has a helper to parse double-quoted string tokens" do
    test_lexer = Class.new(Rly::Lex) do
      lex_double_quoted_string_tokens
    end

    tok = test_lexer.new('"a test"').next
    expect(tok.type).to eq(:STRING)
    expect(tok.value).to eq('a test')
  end
end
