require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Mention do
  describe "new mention with specified links" do
    subject do
      Aji::Mention.new(
        :links => [ "http://duckduckgo.com", "http://google.com" ])
    end

    specify "link strings are converted to Link objects" do
      subject.links.each do |link|
        link.class.should == Aji::Link
      end
    end
  end
  describe "links collection" do
    it "defaults to an empty array" do
      subject.links.class.should == Array
      subject.links.should be_empty
    end

    it "saves and loads like ActiveRecord" do
      link = Aji::Link.new "http://google.com"
      subject.links = [link]
      subject.save
      Aji::Mention.find(subject.id).links.should include link
    end

    it "identifies spam"
  end
end
