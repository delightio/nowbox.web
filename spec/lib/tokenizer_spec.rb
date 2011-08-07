require File.expand_path("../../spec_helper", __FILE__)

describe "String#tokenize" do
  subject { Array.new(10){|n| random_string }.join(' , ') }
  
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
    tokens.should have(10).tokens
    tokens.each {|t| t.downcase.should == t }
  end
end