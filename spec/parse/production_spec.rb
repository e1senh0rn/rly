require "rly/parse/production"

describe Rly::Production do
  subject { Rly::Production.new(1, 'test', ['test', '+', 'test']) }
  it "has a length same as length of its symbols" do
    expect(subject.length).to eq(3)
  end

  it "converts to_s as source -> symbols" do
    expect(subject.to_s).to eq('test -> test + test')
  end

  it "builds a list of unique symbols" do
    expect(subject.usyms).to eq(['test', '+'])
  end
end
