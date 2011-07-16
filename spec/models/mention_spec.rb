require File.expand_path("../../spec_helper", __FILE__)

describe Aji::Mention do
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

    it "identifies spam" do
      spammy_mention = Aji::Mention.new(
        :body => "Win a free iPad for selling ur soul")
      spammy_mention.should be_spam
    end
  end
end
