require File.expand_path("../../spec_helper", __FILE__)

describe "String#tokenize", unit: true do
  subject { "Shoulder,est ,mollit, sint,  Occaecat,deserunt,beef" }

  it "removes leading and trailing space around token" do
    token = subject.tokenize.sample
    token.should == token.strip
  end

  it "removes stopwords" do
    stopwords = %w[ the ]
    stopword = stopwords.sample
    str = "#{subject}, #{stopword}"
    str.tokenize.should_not include stopword
  end

  it "returns array of tokens which are all lower case" do
    tokens = subject.tokenize
    tokens.should have(7).tokens
    tokens.each { |t| t.downcase.should == t }
  end
end
