require "rly"

describe Rly::Lex do
  context "Basic lexer" do
    testLexer = Class.new(Rly::Lex) do
      token :FIRST, /[a-z]+/
      token :SECOND, /[A-Z]+/
    end

    it "has a list of defined tokens" do
      expect(testLexer.tokens.map { |t, r, b| t }).to eq([:FIRST, :SECOND])
    end

    it "outputs tokens one by one" do
      test = 'qweASDzxc'
      l = testLexer.new(test)

      tok = l.next
      expect(tok.type).to eq(:FIRST)
      expect(tok.value).to eq('qwe')

      tok = l.next
      expect(tok.type).to eq(:SECOND)
      expect(tok.value).to eq('ASD')

      tok = l.next
      expect(tok.type).to eq(:FIRST)
      expect(tok.value).to eq('zxc')

      expect(l.next).to be_nil
    end

    it "provides tokens in terminals list" do
      expect(testLexer.terminals).to eq([:FIRST, :SECOND])
    end
  end

  context "Lexer with literals defined" do
    testLexer = Class.new(Rly::Lex) do
      literals "+-*/"
    end

    it "outputs literal tokens" do
      test = '++--'
      l = testLexer.new(test)

      expect(l.next.value).to eq('+')
      expect(l.next.value).to eq('+')
      expect(l.next.value).to eq('-')
      expect(l.next.value).to eq('-')
    end

    it "provides literals in terminals list" do
      expect(testLexer.terminals).to eq(['+', '-', '*', '/'])
    end
  end

  context "Lexer with ignores defined" do
    testLexer = Class.new(Rly::Lex) do
      ignore " \t"
    end

    it "honours ignores list" do
      test = "     \t\t  \t    \t"
      l = testLexer.new(test)

      expect(l.next).to be_nil
    end
  end

  context "Lexer with token that has a block given" do
    testLexer = Class.new(Rly::Lex) do
      token :TEST, /\d+/ do |t|
        t.value = t.value.to_i
        t
      end
    end

    it "calls a block to further process a token" do
      test = "42"
      l = testLexer.new(test)

      expect(l.next.value).to eq(42)
    end
  end

  context "Lexer with unnamed token and block given" do
    testLexer = Class.new(Rly::Lex) do
      token /\n+/ do |t| t.lexer.lineno = t.value.count("\n"); t end
    end

    it "processes but don't output tokens without a name" do
      test = "\n\n\n"
      l = testLexer.new(test)

      expect(l.next).to be_nil

      expect(l.lineno).to eq(3)
    end
  end

  context "Lexer with no error handler" do
    it "raises an error, if there are no suitable tokens" do
      testLexer = Class.new(Rly::Lex) do
        token :NUM, /\d+/
      end
      l = testLexer.new("test")

      expect { l.next } .to raise_error(Rly::LexError)
    end

    it "raises an error, if there is no possible tokens defined" do
      testLexer = Class.new(Rly::Lex) do ; end
      l = testLexer.new("test")

      expect { l.next } .to raise_error(Rly::LexError)
    end
  end

  context "Lexer with error handler" do
    it "calls an error function if it is available, which returns a fixed token" do
      testLexer = Class.new(Rly::Lex) do
        token :NUM, /\d+/
        on_error do |t|
          t.value = "BAD #{t.value}"
          t.lexer.pos += 1
          t
        end
      end
      l = testLexer.new("test")

      tok = l.next
      expect(tok.value).to eq("BAD t")
      expect(tok.type).to eq(:error)

      tok = l.next
      expect(tok.value).to eq("BAD e")
      expect(tok.type).to eq(:error)
    end

    it "calls an error function if it is available, which can skip a token" do
      testLexer = Class.new(Rly::Lex) do
        token :NUM, /\d+/
        on_error do |t|
          t.lexer.pos += 1
          nil
        end
      end
      l = testLexer.new("test1")

      expect(l.next.value).to eq('1')
    end
  end

  it "doesn't try to skip chars over" do
    testLexer = Class.new(Rly::Lex) do
        token :NUM, /\d+/
        literals ","
      end
      l = testLexer.new(",10")

      expect(l.next.type).to eq(',')
      expect(l.next.type).to eq(:NUM)
  end
end
