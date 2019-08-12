require "rly"
require "rly/helpers"

describe "Rly::Yacc Helpers" do
  it "has a helper to use a simpler syntax for action blocks" do
    testParser = Class.new(Rly::Yacc) do
      lexer do
        token :VALUE, /[a-z]+/
      end

      rule 'statement : VALUE', &with_values { |v|
        "stmt#{v}end"
      }
    end

    p = testParser.new
    expect(p.parse("test")).to eq("stmttestend")
  end

  context "rhs value assignment" do
    it "has a helper to assign first rhs value" do
      testParser = Class.new(Rly::Yacc) do
        lexer do
          literals "[]"
          token :VALUE, /[a-z]+/
        end

        rule 'statement : VALUE', &assign_rhs
      end

      p = testParser.new
      expect(p.parse("test")).to eq("test")
    end

    it "has a helper to assign one given rhs value" do
      testParser = Class.new(Rly::Yacc) do
        lexer do
          literals "[]"
          token :VALUE, /[a-z]+/
        end

        rule 'statement : "[" VALUE "]"', &assign_rhs(2)
      end

      p = testParser.new
      expect(p.parse("[test]")).to eq("test")
    end

    it "has a helper to assign first rhs value, assigning nil, if the value is not present" do
      testParser = Class.new(Rly::Yacc) do
        lexer do
          literals "[]"
          token :VALUE, /[a-z]+/
        end

        rule 'statements : statement statement' do |l, s1, s2|
          l.value = [s1.value, s2.value]
        end

        rule 'statement : VALUE
                        |', &assign_rhs
      end

      p = testParser.new
      expect(p.parse("test")).to eq(["test", nil])
    end
  end

  context "collecting values to array" do
    it "works with no separators" do
      testParser = Class.new(Rly::Yacc) do
        lexer do
          ignore " "
          token :VALUE, /[a-z]+/
        end

        rule 'values : VALUE
                     | VALUE values', &collect_to_a
      end

      p = testParser.new
      expect(p.parse("a b c")).to eq(%w[a b c])
    end

    it "works, when there are separators between values" do
      testParser = Class.new(Rly::Yacc) do
        lexer do
          literals ","
          token :VALUE, /[a-z]+/
        end

        rule 'values : VALUE
                     | VALUE "," values', &collect_to_a
      end

      p = testParser.new
      expect(p.parse("a,b,c")).to eq(%w[a b c])
    end
  end

end
